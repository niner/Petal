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
use HTML::Parser;

use vars qw /@NodeStack @MarkedData/;


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
    
    local @MarkedData = ();
    local @NodeStack  = ();
    $data_ref = (ref $data_ref) ? $data_ref : \$data_ref;
    $data_ref = $self->markup_data_ref ($data_ref);
    
    + Petal::Canonicalizer::StartDocument();
    my $tree = HTML::TreeBuilder->new;
    $tree->p_strict (0);
    $tree->no_space_compacting (1);
    $tree->ignore_unknown (0);
    
    eval
    {
	$tree->parse ($$data_ref);
	$tree->elementify();
	$self->generate_events ($tree);
    };
    
    @MarkedData = ();
    @NodeStack  = ();
    $tree->delete;
    carp $@ if (defined $@ and $@);
}


# markup_data_ref

# HTML::TreeBuilder has a tendancy to fix HTML trees, which is not
# so good for included files because we don't want the <body>, <html>,
# etc. tags to be added...
#
# This subroutine will mark the exising tags with a 'petal:mark="1"'
# attribute so that we can throw events only for the marked tags once
# the HTML will have been parsed by HTML::TreeBuilder.
#
# It's a bit contended, but HTML files are usually a big ugly hack so
# I suppose you should not expect anything clean in a modules that deals
# with the HTML which is actually out there...
sub markup_data_ref
{
    my $self = shift;
    my $data_ref = shift;
    my $p = new HTML::Parser;
    $p->handler (start => "markup_start", "tagname, attr");
    $p->handler (end   => "markup_end",   "tagname");
    $p->handler (text  => "markup_text",  "text");
    @MarkedData = ();
    $p->parse ($$data_ref);
    return \do { join '', @MarkedData };
}


sub markup_start
{
    my $tagname = shift;
    my $attr = shift;
    $attr->{'petal:mark'} = 1;    
    $attr = join " ", map { "$_=\"$attr->{$_}\"" } keys %{$attr};
    push @MarkedData, "<$tagname $attr>";
}


sub markup_end
{
    my $tagname = shift;
    push @MarkedData, "</$tagname>";
}


sub markup_text
{
    push @MarkedData, shift;
}

# /markup_data_ref end


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
	    text ($tree->attr ('text')) if (generate_events_is_inside_marked_tag());
	}
	else
	{
	    push @NodeStack, $tree;
	    generate_events_start ($tag, $attr) if (generate_events_is_inside_marked_tag());
	    
	    foreach my $content ($tree->content_list())
	    {
		$self->generate_events ($content);
	    }
	    
	    generate_events_end ($tag) if (generate_events_is_inside_marked_tag());
	    pop (@NodeStack);
	}
    }
    else
    {
	generate_events_text ($tree) if (generate_events_is_inside_marked_tag());
    }
}


sub generate_events_is_inside_marked_tag
{
    foreach (@NodeStack)
    {
	return 1 if $_->attr ('petal:mark');
    }
    return;
}


sub generate_events_start
{
    $_ = shift;
    $_ = "<$_>";
    %_ = %{shift()};
    delete $_{'petal:mark'};
    delete $_{'/'};
    Petal::Canonicalizer::StartTag();
}


sub generate_events_end
{
    $_ = shift;
    $_ = "</$_>";
    Petal::Canonicalizer::EndTag();
}


sub generate_events_text
{
    my $data = shift;
    $data =~ s/\&/&amp;/g;
    $data =~ s/\</&lt;/g;
    $data =~ s/\>/&gt;/g;
    $data =~ s/\"/&quot;/g;
    $_ = $data;
    Petal::Canonicalizer::Text();    
}

# /generate events

1;


__END__
