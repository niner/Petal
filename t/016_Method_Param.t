package main;
use lib ('lib');
use Test;
use CGI;

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
$Petal::OUTPUT = 'XML';

my $cgi = CGI->new();
$cgi->param ('mbox', 'foo');
my $template = new Petal ('method_param.xml');
print $template->process ( cgi => $cgi);
