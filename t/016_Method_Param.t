package main;
use lib ('lib');
use Test;
use CGI;

BEGIN {print "1..3\n";}
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

my $cgi = CGI->new();
$cgi->param ('mbox', 'foo');
my $template = new Petal ('method_param.xml');

my $string = $template->process ( cgi => $cgi);
($string =~ /foo/) ? print "ok 2\n" : print "not ok 2\n";
($string !~ /1/) ? print "ok 3\n" : print "not ok 3\n";
