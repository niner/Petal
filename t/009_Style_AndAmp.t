package main;
use warnings;
use lib ('lib');
use Test;

BEGIN {print "1..3\n";}
END {print "not ok 1\n" unless $loaded;}
use Petal;
$loaded = 1;
print "ok 1\n";

$Petal::BASE_DIR = './t/data/';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;
$Petal::INPUT = 'HTML';
my $template = new Petal ('style_andamp.html');
my $string = $template->process;
($string =~ /\&quot\;/gsm) ? print "not ok 2\n" : print "ok 2\n";

$Petal::INPUT = 'XML';
$template = new Petal ('style_andamp.html');
$string = $template->process;
($string =~ /\&quot\;/gsm) ? print "not ok 3\n" : print "ok 3\n";
