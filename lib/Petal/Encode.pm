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

sub p_decode
{
    return @_ unless ($] > 5.007);
    return @_ unless (scalar @_);
    return Encode::decode ($_[0], $_[1]);
}


sub p_encode
{
    return @_ unless ($] > 5.007);
    return @_ unless (scalar @_);
    return Encode::encode ($_[0], $_[1]);
}


sub p_utf8_on
{
    return @_ unless ($] > 5.007);
    return @_ unless (scalar @_);
    Encode::_utf8_on ($_[1]);
}


sub p_utf8_off
{
    return @_ unless ($] > 5.007);
    return @_ unless (scalar @_);
    Encode::_utf8_off ($_[1]);
}

BEGIN
{
    ($] > 5.007) and do {
        require Encode;
    };
    $@ and warn $@;
}

1;


__END__
