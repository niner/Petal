package Foo;
sub param { shift; return shift }

package main;
use lib ('lib');
use Test;

BEGIN {print "1..2\n";}
END {print "not ok 1\n" unless $loaded;}
use Petal;
$loaded = 1;
print "ok 1\n";

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

(defined $@ and $@) ? print "not ok 2\n" : print "ok 2\n";
