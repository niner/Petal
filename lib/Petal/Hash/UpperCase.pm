=head1 NAME

Petal::Hash::UpperCase - A modifier that uppercases the results
of an expression

=head1 SYNOPSIS

  my $value = $hash->{'some.expression'};
  my $upper_value = $hash->{':uc some.expression'};

=head1 AUTHOR

Jean-Michel Hiver <jhiver@mkdoc.com>

This module is redistributed under the same license as Perl itself.

=head1 SEE ALSO

The template hash module:

  Petal::Hash

=cut
package Petal::Hash::UpperCase;
use strict;
use warnings;


##
# $class->process ($self, $argument);
# -----------------------------------
#   XML encodes the variable specified in $argument and
#   returns it
##
sub process
{
    my $class = shift;
    my $hash  = shift;
    return uc ($hash->FETCH (@_));
}


1;
