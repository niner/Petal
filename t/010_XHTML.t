package main;
use warnings;
use lib ('lib');
use Test;

BEGIN {print "1..5\n";}
END {print "not ok 1\n" unless $loaded;}
use Petal;
$loaded = 1;
print "ok 1\n";

$Petal::BASE_DIR = './t/data/';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;
$Petal::INPUT = 'XML';
$Petal::OUTPUT = 'HTML';
my $template = new Petal ('xhtml.html');
my $string = $template->process;

($string =~ /<\/link>/)  ? print "not ok 2\n" : print "ok 2\n";
($string =~ /<\/br>/)    ? print "not ok 3\n" : print "ok 3\n";
($string =~ /<\/hr>/)    ? print "not ok 4\n" : print "ok 4\n";
($string =~ /<\/input>/) ? print "not ok 5\n" : print "ok 5\n";
