#!/usr/bin/perl

##
## Test auto-creation of nested variables when set in the template
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

my $string;
eval { $string = Petal->new( 'set_nested_var.html' )->process(); };

TODO: {
    local $TODO = 'set nested values not implemented';
    if ($@)
    {
	fail( 'died after process()' );
	diag($@);
    }
    else
    {
	like( $string, qr/ok: my defined/,         "hash 'my' created" );
	like( $string, qr/ok: my-test defined/,    "hash 'my/test' created" );
	like( $string, qr/ok: my-test-fu defined/, "hash 'my/test/fu' created" );
	like( $string, qr/ok: foo defined/,        "hash 'foo' created" );
	like( $string, qr/ok: foo-1 defined/,      "array 'foo/1' created" );
    }
}

