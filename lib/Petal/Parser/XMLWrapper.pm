=head1 NAME

Petal::Parser::XMLWrapper

=head1 DESCRIPTION

A Wrapper class for XML::Parser that is meant to be used
with XML::Template::Pal::Canonicalizer.

=cut
package Petal::Parser::XMLWrapper;
use strict;
use warnings;

use Petal::Canonicalizer;
use XML::Parser;


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
    
    my $parser = new XML::Parser (
	Style => 'Stream',
	Pkg   => 'Petal::Canonicalizer'
       );
    
    $parser->parse ($$data_ref);
}


1;


__END__
