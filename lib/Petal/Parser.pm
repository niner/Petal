# ------------------------------------------------------------------
# Petal::Parser - Fires Petal::Canonicalizer events
# ------------------------------------------------------------------
# A Wrapper class for MKDoc::XML:TreeBuilder which is meant to be
# used for Petal::Canonicalizer.
# ------------------------------------------------------------------
package Petal::Parser;
use MKDoc::XML::TreeBuilder;
use MKDoc::XML::Decode;
use strict;
use warnings;
use Carp;

use Petal::Canonicalizer::XML;
use Petal::Canonicalizer::XHTML;

use vars qw /@NodeStack @MarkedData $Canonicalizer
	     @NameSpaces @XI_NameSpaces/;


# this avoid silly warnings
sub sillyness
{
    $Petal::NS,
    $Petal::NS_URI,
    $Petal::XI_NS_URI;
}


sub new
{
    my $class = shift;
    $class = ref $class || $class;
    return bless { @_ }, $class;
}


sub process
{
    my $self = shift;
    local $Canonicalizer = shift;
    my $data_ref = shift;
    local @MarkedData = ();
    local @NodeStack  = ();
    local @NameSpaces = ();
    $data_ref = (ref $data_ref) ? $data_ref : \$data_ref;
    
    my @top_nodes = MKDoc::XML::TreeBuilder->process_data ($$data_ref);
    for (@top_nodes) { $self->generate_events ($_) }
    
    @MarkedData = ();
    @NodeStack  = ();
}


# generate_events();
# ------------------
# Once the HTML::TreeBuilder object is built and elementified, it is
# passed to that subroutine which will traverse it and will trigger
# proper subroutines which will generate the XML events which are used
# by the Petal::Canonicalizer module
sub generate_events
{
    my $self = shift;
    my $tree = shift;
    
    if (ref $tree)
    {
	my $tag  = $tree->{_tag};	
	my $attr = { map { /^_/ ? () : ( $_ => MKDoc::XML::Decode->process ($tree->{$_}) ) } keys %{$tree} };
	
	if ($tag eq '~comment')
	{
	    generate_events_comment ($tree->{text});
	}
	else
	{
	    # decode attributes
	    for (keys %{$tree})
	    {
		$tree->{$_} = MKDoc::XML::Decode->process ( $tree->{$_} )
		   unless (/^_/);
	    }
	    
	    push @NodeStack, $tree;
	    generate_events_start ($tag, $attr);
	    
	    foreach my $content (@{$tree->{_content}})
	    {
		$self->generate_events ($content);
	    }
	    
	    generate_events_end ($tag);
	    pop (@NodeStack);
	}
    }
    else
    {
	$tree = MKDoc::XML::Decode->process ( $tree );
	generate_events_text ($tree);
    }
}


sub generate_events_start
{
    local $_ = shift;
    $_ = "<$_>";
    local %_ = %{shift()};
    delete $_{'/'};

    # process the Petal namespace...
    my $ns = (scalar @NameSpaces) ? $NameSpaces[$#NameSpaces] : $Petal::NS;
    foreach my $key (keys %_)
    {
	my $value = $_{$key};
	if ($value eq $Petal::NS_URI)
	{
	    next unless ($key =~ /^xmlns\:/);
	    delete $_{$key};
	    $ns = $key;
	    $ns =~ s/^xmlns\://;
	}
    }
    
    push @NameSpaces, $ns;
    local ($Petal::NS) = $ns;
    
    # process the XInclude namespace
    my $xi_ns = (scalar @XI_NameSpaces) ? $XI_NameSpaces[$#XI_NameSpaces] : $Petal::XI_NS;
    foreach my $key (keys %_)
    {
	my $value = $_{$key};
	if ($value eq $Petal::XI_NS_URI)
	{
	    next unless ($key =~ /^xmlns\:/);
	    delete $_{$key};
	    $xi_ns = $key;
	    $xi_ns =~ s/^xmlns\://;
	}
    }
    
    push @XI_NameSpaces, $xi_ns;
    local ($Petal::XI_NS) = $xi_ns;
    
    $Canonicalizer->StartTag();
}


sub generate_events_end
{
    local $_ = shift;
    local $_ = "</$_>";
    local ($Petal::NS) = pop (@NameSpaces);
    local ($Petal::XI_NS) = pop (@XI_NameSpaces);
    $Canonicalizer->EndTag();
}


sub generate_events_text
{
    my $data = shift;
    $data =~ s/\&/&amp;/g;
    $data =~ s/\</&lt;/g;
    local $_ = $data;
    local ($Petal::NS) = $NameSpaces[$#NameSpaces];
    local ($Petal::XI_NS) = $XI_NameSpaces[$#XI_NameSpaces];
    $Canonicalizer->Text();
}


sub generate_events_comment
{
    my $data = shift;
    $data =~ s/\&/&amp;/g;
    $data =~ s/\</&lt;/g;
    local $_ = '<!--' . $data . '-->';
    $Canonicalizer->Text();    
}


1;


__END__
