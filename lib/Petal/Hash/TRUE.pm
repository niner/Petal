=head1 NAME

Petal::Hash::TRUE - A modifier that evaluates the 'trueness' of an
expression

=head1 SYNOPSIS

  my $is_true = $hash->{':true some.expression'};

=head1 AUTHOR

Jean-Michel Hiver <jhiver@mkdoc.com>

This module is redistributed under the same license as Perl itself.


=head1 SEE ALSO

The template hash module:

  Petal::Hash

=cut
package Petal::Hash::TRUE;
use strict;
use warnings;


sub process
{
    my $class = shift;
    my $hash  = shift;
    my $variable = $hash->FETCH (@_);
    return unless (defined $variable);
    
    (scalar @{$variable}) ? return 1 : return
        if (ref $variable eq 'ARRAY' or (ref $variable and $variable =~ /=ARRAY\(/));
    
    ($variable) ? return 1 : return;
}


1;
