#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';
use Petal;

$Petal::BASE_DIR     = './t/data/';
$Petal::DISK_CACHE   = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::DECODE_CHARSET = 'UTF-8';
$Petal::ENCODE_CHARSET = 'UTF-8';
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT        = 1;
$Petal::INPUT        = 'XHTML';
$Petal::OUTPUT       = 'XHTML';

ok (1);
if ($] > 5.007)
{
    my $string = Petal->new ( 'entities.html' )->process();
    like ($string, qr/©/ => 'Copyright');
    like ($string, qr/®/ => 'Registered');
}

