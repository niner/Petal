=head1 NAME

Petal::Parser::XMLWrapper

=head1 DESCRIPTION

A Wrapper class for XML::Parser that is meant to be used
with XML::Template::Pal::Canonicalizer.

=cut
package Petal::Parser::XMLWrapper;
use strict;
use warnings;

use Petal::Canonicalizer::XML;
use Petal::Canonicalizer::XHTML;
use XML::Parser;

use vars qw /$Canonicalizer @NameSpaces/;


# this avoid silly warnings
sub sillyness
{
    $Petal::NS,
    $Petal::NS_URI;
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
    local @NameSpaces = ();
    
    my $data_ref = shift;
    $data_ref = (ref $data_ref) ? $data_ref : \$data_ref;
    my $parser = new XML::Parser (
	Style    => 'Stream',
	Pkg      => ref $self,
       );
    
    $parser->parse ($$data_ref);
}


sub StartTag
{
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


sub EndTag
{
    local ($Petal::NS) = pop (@NameSpaces);
    $Canonicalizer->EndTag()
}


sub Text
{
    local ($Petal::NS) = $NameSpaces[$#NameSpaces];
    s/\&/\&amp;/g;
    s/\</\&lt\;/g;
    $Canonicalizer->Text();
}


1;


__END__
