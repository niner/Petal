=head1 NAME

Petal::Hash::String - Interpolates variables with other strings in Petal attributes

=head1 SYNOPSIS

  my $value = $hash->{'string: This is a test ${foo/bar}'}

=head1 AUTHOR

Jean-Michel Hiver <jhiver@mkdoc.com>

This module is redistributed under the same license as Perl itself.


=head1 SEE ALSO

The template hash module:

  Petal::Hash

=cut
package Petal::Hash::String;
use strict;
use warnings;
use Carp;


our $VARIABLE_RE_SIMPLE   = qq |\\\$[A-Za-z][A-Za-z0-9_\\.:\/]+|;
our $VARIABLE_RE_BRACKETS = qq |\\\$(?<!\\\\)\\{.*?(?<!\\\\)\\}|;
our $TOKEN_RE             = "(?:$VARIABLE_RE_SIMPLE|$VARIABLE_RE_BRACKETS)";


sub process
{
    my $self = shift;
    my $hash = shift;
    my $argument = shift;

    my @interpolate = $argument =~ /($TOKEN_RE)/gsm;
    for (@interpolate)
    {
	my $from = quotemeta ($_);
	s/^\$//;
	my $to   = $hash->FETCH ($_);
	$argument =~ s/$from/$to/;
    }
    
    return $argument;
}


1;


__END__
