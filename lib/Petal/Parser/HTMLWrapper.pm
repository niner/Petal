=head1 NAME

Petal::Parser::HTMLWrapper - Fires Petal::Canonicalizer events from HTML

=head1 DESCRIPTION

A Wrapper class for HTML::Parser that is meant to be used for
Petal::Canonicalizer. This module should happily parse the million
gadzillon HTML pages out there which are not valid XML...

=cut
package Petal::Parser::HTMLWrapper;
use strict;
use warnings;
use Carp;
use HTML::TreeBuilder;
use HTML::Parser;

use Petal::Canonicalizer::XML;
use Petal::Canonicalizer::XHTML;


use vars qw /@NodeStack @MarkedData $Canonicalizer @NameSpaces/;


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
    
    my $tree = HTML::TreeBuilder->new;
    $tree->p_strict (0);
    $tree->no_space_compacting (1);
    $tree->ignore_unknown (0);
    $tree->store_comments(1);
    $tree->ignore_ignorable_whitespace(0);
    
    eval
    {
	$tree->parse ($$data_ref);
	my @nodes = $tree->guts();
	$tree->elementify();
	$self->generate_events ($_) for (@nodes);
    };
    
    @MarkedData = ();
    @NodeStack  = ();
    $tree->delete;
    carp $@ if (defined $@ and $@);
}


# generate_events
#
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
	my $tag  = $tree->tag;
	my $attr = { $tree->all_external_attr() };
	
	if ($tag eq '~comment')
	{
	    generate_events_comment ($tree->attr ('text'));
	}
	else
	{
	    push @NodeStack, $tree;
	    generate_events_start ($tag, $attr);
	    
	    foreach my $content ($tree->content_list())
	    {
		$self->generate_events ($content);
	    }
	    
	    generate_events_end ($tag);
	    pop (@NodeStack);
	}
    }
    else
    {
	generate_events_text ($tree);
    }
}


sub generate_events_start
{
    $_ = shift;
    $_ = "<$_>";
    %_ = %{shift()};
    delete $_{'/'};
    
    my $ns = (scalar @NameSpaces) ? $NameSpaces[$#NameSpaces] : $Petal::NS;
    foreach my $key (keys %_)
    {
	my $value = $_{$key};
	if ($value eq $Petal::NS_URI)
	{
	    delete $_{$key};
	    $ns = $key;
	    $ns =~ s/^xmlns\://;
	}
    }
    
    push @NameSpaces, $ns;
    local ($Petal::NS) = $ns;
    $Canonicalizer->StartTag();
}


sub generate_events_end
{
    $_ = shift;
    $_ = "</$_>";
    local ($Petal::NS) = pop (@NameSpaces);
    $Canonicalizer->EndTag();
}


sub generate_events_text
{
    my $data = shift;
    $data =~ s/\&/&amp;/g;
    $data =~ s/\</&lt;/g;
    $_ = $data;
    
    local ($Petal::NS) = $NameSpaces[$#NameSpaces];
    $Canonicalizer->Text();    
}


sub generate_events_comment
{
    my $data = shift;
    $data =~ s/\&/&amp;/g;
    $data =~ s/\</&lt;/g;
    $_ = '<!--' . $data . '-->';
    $Canonicalizer->Text();    
}




1;


__END__
