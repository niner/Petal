=head1 NAME

Petal::XML_Encode_Decode - Minimalistic module to encode / decode XML text


=head1 SYNOPSIS

  my $foo = "Foo & Bar";
  my $encoded_foo = Petal::XML_Encode_Decode::encode ($foo); # "Foo &amp; Bar"
  print $foo eq Petal::XML_Encode_Decode::decode ($foo); # should print 1

=head1 DESCRIPTION

I had to do that operation in different places for different reasons,
thus although it's not much code it's been moved it into a namespace
of its own.

=head1 AUTHOR

Jean-Michel Hiver <jhiver@mkdoc.com>

This module is redistributed under the same license as Perl itself.

=cut
package Petal::XML_Encode_Decode;
use strict;
use warnings;


sub encode
{
    my $data = shift;
    $data =~ s/\&/&amp;/g;
    $data =~ s/\</&lt;/g;
    $data =~ s/\>/&gt;/g;
    $data =~ s/\"/&quot;/g;
    return $data;
}


sub encode_backslash_semicolon
{
    my $data = shift;
    $data =~ s/\&/&amp\\;/g;
    $data =~ s/\</&lt\\;/g;
    $data =~ s/\>/&gt\\;/g;
    $data =~ s/\"/&quot\\;/g;
    return $data;
}


sub decode
{
    my $data = shift;
    $data =~ s/\&quot;/\"/g;
    $data =~ s/\&gt;/\>/g;
    $data =~ s/\&lt;/\</g;
    $data =~ s/\&amp;/\&/g;
    return $data;
}


sub decode_backslash_semicolon
{
    my $data = shift;
    $data =~ s/\&quot\\;/\"/g;
    $data =~ s/\&gt\\;/\>/g;
    $data =~ s/\&lt\\;/\</g;
    $data =~ s/\&amp\\;/\&/g;
    return $data;
}


1;


__END__
