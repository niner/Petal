#!/usr/bin/perl

##
## Test accessing object hashes / arrays when no methods found.
##

use warnings;
use lib 'lib';

use Test::More qw( no_plan );
use Petal;

$Petal::BASE_DIR     = './t/data/';
$Petal::DISK_CACHE   = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT        = 1;
$Petal::INPUT        = 'HTML';

{
    my $foo = bless { bar => 1 }, 'Foo';
    my $string = Petal->new( 'access_obj_hash.html' )->process( foo => $foo );
    like( $string, qr/ok: bar/, 'accessed [bar] var in [foo]' );
}

{
    my $foo = bless [ bar => 1 ], 'Foo';
    my $string = Petal->new( 'access_obj_array.html' )->process( foo => $foo );
    like( $string, qr/ok: index 0/, 'accessed index 0 of [foo]' );
}

