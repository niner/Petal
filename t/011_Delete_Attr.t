package main;
use warnings;
use lib ('lib');
use Test;

BEGIN {print "1..4\n";}
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

my $template = new Petal ('delete_attribute.xml');
my $string = $template->process;
($string =~ /type/) ? print "not ok 2\n" : print "ok 2\n";

$Petal::OUTPUT = 'HTML';
$template = new Petal ('delete_attribute.xml');
$string = $template->process;
($string =~ /type/) ? print "not ok 3\n" : print "ok 3\n";

($string =~ /\Qbar="0"\E/) ? print "ok 4\n" : print "not ok 4\n";
