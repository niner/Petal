=head1 NAME

Petal::Hash::FALSE - A modifier that evaluates the 'falseness' of an
expression

=head1 SYNOPSIS

  my $is_false = $hash->{':false some.expression'};

=head1 AUTHOR

Jean-Michel Hiver <jhiver@mkdoc.com>

This module is redistributed under the same license as Perl itself.


=head1 SEE ALSO

The template hash module:

  Petal::Hash

=cut
package Petal::Hash::FALSE;
use strict;
use warnings;
use base qw /Petal::Hash::TRUE/;


sub process
{
    my $class = shift;
    return not $class->SUPER::process (@_);
}


1;
