package Foo;
sub param { shift; return shift }

package main;
use warnings;
use lib ('lib');
use Test::More tests => 2;
use Petal;
pass("loaded");

$Petal::BASE_DIR = './t/data/';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;
$Petal::INPUT = 'XML';
my $template = new Petal ('quoted_params.xml');

my $cgi = bless {}, 'Foo';

eval {
    my $string = $template->process ( cgi => $cgi );
};

ok(! (defined $@ and $@), "ran") || diag $@;
