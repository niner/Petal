# ------------------------------------------------------------------
# Petal::Encode - Petal's wrapper around Encode
# ------------------------------------------------------------------
# Author: Jean-Michel Hiver
# Description: Wraps around Encode only if using right version
# of Perl.
# ------------------------------------------------------------------
package Petal::Encode;
use strict;
use warnings;


($] > 5.007) and do {
    require Encode;
};
$@ and die $@;


sub decode
{
    return @_ unless ($] > 5.007);
    return Encode::decode (@_);
}


sub encode
{
    return @_ unless ($] > 5.007);
    return Encode::encode (@_);
}


sub _utf8_on
{
    return @_ unless ($] > 5.007);
    return Encode::_utf8_on (@_);
}


sub _utf8_off
{
    return @_ unless ($] > 5.007);
    return Encode::_utf8_off (@_);
}


sub is_utf8
{
    return @_ unless ($] > 5.007);
    return Encode::is_utf8 (@_);    
}


1;


__END__
