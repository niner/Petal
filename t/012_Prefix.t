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
$Petal::OUTPUT = 'XML';

my $template = new Petal ('prefix.xml');
my $string = $template->process;
($string =~ /<some:stuff>/) ? print "ok 2\n" : print "not ok 2\n";
($string =~ /<\/some:stuff>/) ? print "ok 3\n" : print "not ok 3\n";


$Petal::INPUT = 'HTML';
$template = new Petal ('prefix.xml');
$string = $template->process;
($string =~ /<some:stuff>/) ? print "ok 4\n" : print "not ok 4\n";
($string =~ /<\/some:stuff>/) ? print "ok 5\n" : print "not ok 5\n";
