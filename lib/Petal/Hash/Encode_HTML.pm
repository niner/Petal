=head1 NAME

Petal::Hash::Encode_HTML - A modifier that encodes hash values to HTML

=head1 SYNOPSIS

  my $value = $hash->{'some.expression'};
  my $value_html = $hash->{':encode some.expression'};

=head1 DESCRIPTION

A simple modifier which encodes values as HTML, i.e. turns '&', '<', '>'
and '"' into '&amp;' '&lt;' '&gt;' and '&quot;' respectively.

=head1 AUTHOR

Lucas Marinho <lucas.marinho@uol.com.br>

This module is redistributed under the same license as Perl itself.

=head1 SEE ALSO

The template hash module:

  Petal::Hash

=cut
package Petal::Hash::Encode_HTML;
use strict;
use warnings;
use base qw /Petal::Hash::VAR/;

##
# $class->process ($self, $argument);
# -----------------------------------
#   HTML encodes the variable specified in $argument and
#   returns it
##
sub process
{
    my $class = shift;
    return text2html ($class->SUPER::process (@_));
}


##
# text2html ($data);
# -----------------
#   Converts $data to HTML
#
#   @param : $data - text $data
#   @returns : $data encoded as html
##
sub text2html
{

  my %subst = ();
  my %char2entity = ();

  my %entities_table = (
   amp    => '&',
   'gt'   => '>',
   'lt'   => '<',
   quot   => '"',
   apos   => "'",
   AElig  => 'Æ',
   Aacute => 'Á',
   Acirc  => 'Â',
   Agrave => 'À',
   Aring  => 'Å',
   Atilde => 'Ã',
   Auml	  => 'Ä',
   Ccedil => 'Ç',
   ETH	  => 'Ð',
   Eacute => 'É',
   Ecirc  => 'Ê',
   Egrave => 'È',
   Euml	  => 'Ë',
   Iacute => 'Í',
   Icirc  => 'Î',
   Igrave => 'Ì',
   Iuml	  => 'Ï',
   Ntilde => 'Ñ',
   Oacute => 'Ó',
   Ocirc  => 'Ô',
   Ograve => 'Ò',
   Oslash => 'Ø',
   Otilde => 'Õ',
   Ouml	  => 'Ö',
   THORN  => 'Þ',
   Uacute => 'Ú',
   Ucirc  => 'Û',
   Ugrave => 'Ù',
   Uuml	  => 'Ü',
   Yacute => 'Ý',
   aacute => 'á',
   acirc  => 'â',
   aelig  => 'æ',
   agrave => 'à',
   aring  => 'å',
   atilde => 'ã',
   auml	  => 'ä',
   ccedil => 'ç',
   eacute => 'é',
   ecirc  => 'ê',
   egrave => 'è',
   eth	  => 'ð',
   euml	  => 'ë',
   iacute => 'í',
   icirc  => 'î',
   igrave => 'ì',
   iuml	  => 'ï',
   ntilde => 'ñ',
   oacute => 'ó',
   ocirc  => 'ô',
   ograve => 'ò',
   oslash => 'ø',
   otilde => 'õ',
   ouml	  => 'ö',
   szlig  => 'ß',
   thorn  => 'þ',
   uacute => 'ú',
   ucirc  => 'û',
   ugrave => 'ù',
   uuml	  => 'ü',
   yacute => 'ý',
   yuml	  => 'ÿ',
   copy   => '©',
   reg    => '®',
   nbsp   => "\240",
   iexcl  => '¡',
   cent   => '¢',
   pound  => '£',
   curren => '¤',
   yen    => '¥',
   brvbar => '¦',
   sect   => '§',
   uml    => '¨',
   ordf   => 'ª',
   laquo  => '«',
   'not'  => '¬',
   shy    => '­',
   macr   => '¯',
   deg    => '°',
   plusmn => '±',
   sup1   => '¹',
   sup2   => '²',
   sup3   => '³',
   acute  => '´',
   micro  => 'µ',
   para   => '¶',
   middot => '·',
   cedil  => '¸',
   ordm   => 'º',
   raquo  => '»',
   frac14 => '¼',
   frac12 => '½',
   frac34 => '¾',
   iquest => '¿',
   'times'=> '×',
   divide => '÷',

   ( $] > 5.007 ? (
     OElig    => chr(338),
     oelig    => chr(339),
     Scaron   => chr(352),
     scaron   => chr(353),
     Yuml     => chr(376),
     fnof     => chr(402),
     circ     => chr(710),
     tilde    => chr(732),
     Alpha    => chr(913),
     Beta     => chr(914),
     Gamma    => chr(915),
     Delta    => chr(916),
     Epsilon  => chr(917),
     Zeta     => chr(918),
     Eta      => chr(919),
     Theta    => chr(920),
     Iota     => chr(921),
     Kappa    => chr(922),
     Lambda   => chr(923),
     Mu       => chr(924),
     Nu       => chr(925),
     Xi       => chr(926),
     Omicron  => chr(927),
     Pi       => chr(928),
     Rho      => chr(929),
     Sigma    => chr(931),
     Tau      => chr(932),
     Upsilon  => chr(933),
     Phi      => chr(934),
     Chi      => chr(935),
     Psi      => chr(936),
     Omega    => chr(937),
     alpha    => chr(945),
     beta     => chr(946),
     gamma    => chr(947),
     delta    => chr(948),
     epsilon  => chr(949),
     zeta     => chr(950),
     eta      => chr(951),
     theta    => chr(952),
     iota     => chr(953),
     kappa    => chr(954),
     lambda   => chr(955),
     mu       => chr(956),
     nu       => chr(957),
     xi       => chr(958),
     omicron  => chr(959),
     pi       => chr(960),
     rho      => chr(961),
     sigmaf   => chr(962),
     sigma    => chr(963),
     tau      => chr(964),
     upsilon  => chr(965),
     phi      => chr(966),
     chi      => chr(967),
     psi      => chr(968),
     omega    => chr(969),
     thetasym => chr(977),
     upsih    => chr(978),
     piv      => chr(982),
     ensp     => chr(8194),
     emsp     => chr(8195),
     thinsp   => chr(8201),
     zwnj     => chr(8204),
     zwj      => chr(8205),
     lrm      => chr(8206),
     rlm      => chr(8207),
     ndash    => chr(8211),
     mdash    => chr(8212),
     lsquo    => chr(8216),
     rsquo    => chr(8217),
     sbquo    => chr(8218),
     ldquo    => chr(8220),
     rdquo    => chr(8221),
     bdquo    => chr(8222),
     dagger   => chr(8224),
     Dagger   => chr(8225),
     bull     => chr(8226),
     hellip   => chr(8230),
     permil   => chr(8240),
     prime    => chr(8242),
     Prime    => chr(8243),
     lsaquo   => chr(8249),
     rsaquo   => chr(8250),
     oline    => chr(8254),
     frasl    => chr(8260),
     euro     => chr(8364),
     image    => chr(8465),
     weierp   => chr(8472),
     real     => chr(8476),
     trade    => chr(8482),
     alefsym  => chr(8501),
     larr     => chr(8592),
     uarr     => chr(8593),
     rarr     => chr(8594),
     darr     => chr(8595),
     harr     => chr(8596),
     crarr    => chr(8629),
     lArr     => chr(8656),
     uArr     => chr(8657),
     rArr     => chr(8658),
     dArr     => chr(8659),
     hArr     => chr(8660),
     forall   => chr(8704),
     part     => chr(8706),
     exist    => chr(8707),
     empty    => chr(8709),
     nabla    => chr(8711),
     isin     => chr(8712),
     notin    => chr(8713),
     ni       => chr(8715),
     prod     => chr(8719),
     sum      => chr(8721),
     minus    => chr(8722),
     lowast   => chr(8727),
     radic    => chr(8730),
     prop     => chr(8733),
     infin    => chr(8734),
     ang      => chr(8736),
     'and'    => chr(8743),
     'or'     => chr(8744),
     cap      => chr(8745),
     cup      => chr(8746),
     'int'    => chr(8747),
     there4   => chr(8756),
     sim      => chr(8764),
     cong     => chr(8773),
     asymp    => chr(8776),
     'ne'     => chr(8800),
     equiv    => chr(8801),
     'le'     => chr(8804),
     'ge'     => chr(8805),
     'sub'    => chr(8834),
     sup      => chr(8835),
     nsub     => chr(8836),
     sube     => chr(8838),
     supe     => chr(8839),
     oplus    => chr(8853),
     otimes   => chr(8855),
     perp     => chr(8869),
     sdot     => chr(8901),
     lceil    => chr(8968),
     rceil    => chr(8969),
     lfloor   => chr(8970),
     rfloor   => chr(8971),
     lang     => chr(9001),
     rang     => chr(9002),
     loz      => chr(9674),
     spades   => chr(9824),
     clubs    => chr(9827),
     hearts   => chr(9829),
     diams    => chr(9830),
   ) : ())
  );

  while (my($entity, $char) = each(%entities_table)) {
    $char2entity{$char} = "&$entity;";
  }
  delete($char2entity{"'"});

  local $_;
  for (0 .. 255) {
    next if(exists($char2entity{chr($_)}));
    $char2entity{chr($_)} = "&#$_;";
  }

  my $ref;
  if (defined(wantarray)) {
    my $x = $_[0];
    $ref = \$x;
  } else {
    $ref = \$_[0];
  }
  if (defined($_[1])) {
    unless (exists($subst{$_[1]})) {
      $subst{$_[1]} = eval "sub {\$_[0] =~ s/([$_[1]])/\$char2entity{\$1} || _num_entity(\$1)/ge; }";
      die $@ if($@);
    }
    &{$subst{$_[1]}}($$ref);
  } else {
    $$ref =~ s/([^\n\r\t !\#\$%\'-;=?-~])/$char2entity{$1} || _num_entity($1)/ge;
  }
  return $$ref;
}

sub _num_entity {
  sprintf("&#x%X;", ord(shift()));
}

1;