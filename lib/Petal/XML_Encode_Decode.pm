# ------------------------------------------------------------------
# Petal::XML_Encode_Decode - Minimalistic module to encode XML text
# ------------------------------------------------------------------
# Thanks to Fergal Daly <fergal@esatclear.ie> for the patch!
# ------------------------------------------------------------------
package Petal::XML_Encode_Decode;
use strict;
use warnings;

my %xml_encode = (
	'&' => 'amp',
	'<' => 'lt',
	'>' => 'gt',
	'"' => 'quot',
);
my $xml_encode_pat = join("|", keys %xml_encode);
my %xml_decode     = reverse(%xml_encode);
my $xml_decode_pat = join("|", keys %xml_decode);


sub encode
{
    my $data = shift;
    $data =~ s/($xml_encode_pat)/&$xml_encode{$1};/go;
    return $data;
}


sub encode_backslash_semicolon
{
    my $data = shift;
    $data =~ s/($xml_encode_pat)/&$xml_encode{$1}\\;/go;
    return $data;
}


sub decode
{
    my $data = shift;
    $data =~ s/&($xml_decode_pat);/$xml_decode{$1}/go;
    return $data;
}


sub decode_backslash_semicolon
{
    my $data = shift;
    $data =~ s/&($xml_decode_pat)\\;/$xml_decode{$1}/go;
    return $data;
}


1;


__END__
