=head1 NAME

Petal::Parser::HTMLWrapper

=head1 DESCRIPTION

A Wrapper class for HTML::Parser that is meant to be used for
Petal::Canonicalizer. This module should happily parse the million
gadzillon HTML pages out there which are not valid XML...

=cut
package Petal::Parser::HTMLWrapper;
use strict;
use warnings;
use Carp;

use Petal::Canonicalizer;
use HTML::TreeBuilder;

use vars qw /$IsInclude @NodeStack/;


sub new
{
    my $class = shift;
    $class = ref $class || $class;
    return bless { @_ }, $class;
}


sub process
{
    my $self = shift;
    my $data_ref = shift;
    $data_ref = (ref $data_ref) ? $data_ref : \$data_ref;
    
    $IsInclude = not ($$data_ref =~ /<html>/i);
    @NodeStack = ();
    
    + Petal::Canonicalizer::StartDocument();
    my $tree = HTML::TreeBuilder->new;
    $tree->p_strict (0);
    $tree->no_space_compacting(1);
    $tree->ignore_unknown(0);
    
    eval
    {
	$tree->parse ($$data_ref);
	$tree->elementify();
	$self->generate_events ($tree);
    };
    
    $tree->delete;
    carp $@ if (defined $@ and $@);
}


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
	    text ($tree->attr ('text'));
	}
	else
	{
	    start ($tag, $attr) if (not $IsInclude or is_inside_body());
	    push @NodeStack, $tree;
	    foreach my $content ($tree->content_list())
	    {
		$self->generate_events ($content);
	    }
	    pop (@NodeStack);
	    end ($tag) if (not $IsInclude or is_inside_body());
	}
    }
    else
    {
	text ($tree);
    }
}


sub is_inside_body
{
    foreach (@NodeStack)
    {
	return 1 if $_->tag eq 'body';
    }
    return;
}


sub start
{
    $_ = shift;
    $_ = "<$_>";
    %_ = %{shift()};
    delete $_{'/'};
    Petal::Canonicalizer::StartTag();
}


sub end
{
    $_ = shift;
    $_ = "</$_>";
    Petal::Canonicalizer::EndTag();
}


sub text
{
    my $data = shift;
    $data =~ s/\&/&amp;/g;
    $data =~ s/\</&lt;/g;
    $data =~ s/\>/&gt;/g;
    $data =~ s/\"/&quot;/g;
    $_ = $data;
    Petal::Canonicalizer::Text();    
}


1;


__END__
