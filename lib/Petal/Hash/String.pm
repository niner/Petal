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


our $VARIABLE_RE_SIMPLE   = qq |\\\$[A-Za-z_][A-Za-z0-9_\\.:\/]+|;
our $VARIABLE_RE_BRACKETS = qq |\\\$(?<!\\\\)\\{.*?(?<!\\\\)\\}|;
our $TOKEN_RE             = "(?:$VARIABLE_RE_SIMPLE|$VARIABLE_RE_BRACKETS)";


sub process
{
    my $self = shift;
    my $hash = shift;
    my $argument = shift;
    
    my $tokens = $self->_tokenize (\$argument);
    my @res = map {
	($_ =~ /$TOKEN_RE/gsm) ?
	    do {
		s/^\$//;
		s/^\{//;
		s/\}$//;
		$hash->fetch ($_);
	    } :
	    do {
		s/\\(.)/$1/gsm;
		$_;
	    };
    } @{$tokens};
    
    return join '', @res;
}


# $class->_tokenize ($data_ref);
# ------------------------------
#   Returns the data to process as a list of tokens:
#   ( 'some text', '<% a_tag %>', 'some more text', '<% end-a_tag %>' etc.
sub _tokenize
{
    my $self = shift;
    my $data_ref = shift;
    
    my @tokens = $$data_ref =~ /($TOKEN_RE)/gs;
    my @split  = split /$TOKEN_RE/s, $$data_ref;
    my $tokens = [];
    while (@split)
    {
        push @{$tokens}, shift (@split);
        push @{$tokens}, shift (@tokens) if (@tokens);
    }
    push @{$tokens}, (@tokens);
    return $tokens;
}


1;


__END__
