package Foo;
sub add { return $_[1] + $_[2] };

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
$Petal::PARSER = 'HTML';
my $template = new Petal ('string.xml');

my $string = $template->process (
	user => { name => 'Bruno Postle' },
	number => 2,
	math => bless {}, 'Foo'
);

($string =~ /Hello, Bruno Postle, 2 \+ 2 = 4/) ? print "ok 2\n" : print "not ok 2\n";
