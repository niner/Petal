=head1 NAME

Petal::Hash::Encode_XML - A modifier that encodes hash values to XML

=head1 SYNOPSIS

  my $value = $hash->{'some.expression'};
  my $value_xml = $hash->{':encode some.expression'};

=head1 DESCRIPTION

A simple modifier which encodes values as XML, i.e. turns '&', '<', '>'
and '"' into '&amp;' '&lt;' '&gt;' and '&quot;' respectively.

=head1 AUTHOR

Jean-Michel Hiver <jhiver@mkdoc.com>

This module is redistributed under the same license as Perl itself.

=head1 SEE ALSO

The template hash module:

  Petal::Hash

=cut
package Petal::Hash::Encode_XML;
use strict;
use warnings;
use base qw /Petal::Hash::VAR/;


##
# $class->process ($self, $argument);
# -----------------------------------
#   XML encodes the variable specified in $argument and
#   returns it
##
sub process
{
    my $class = shift;
    return text2xml ($class->SUPER::process (@_));
}


##
# text2xml ($data);
# -----------------
#   Converts $data to XML
#
#   @param : $data - text $data
#   @returns : $data encoded as XML
##
sub text2xml
{
    my $data = join '', @_;
    $data =~ s/\&/&amp;/g;
    $data =~ s/\</&lt;/g;
    $data =~ s/\>/&gt;/g;
    $data =~ s/\"/&quot;/g;
    return $data;
}


1;
