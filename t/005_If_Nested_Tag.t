use warnings;
use lib ('lib');
use Test;

BEGIN {print "1..5\n";}
END {print "not ok 1\n" unless $loaded;}
use Petal;
$loaded = 1;
print "ok 1\n";

$Petal::BASE_DIR = './t/data';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;

my $template_file = 'if.xml';
my $template = new Petal ($template_file);

($template->process =~ /\<p\>/) ? print "not ok 2\n" : print "ok 2\n";
($template->process (error => 'Some error message') =~ /Some error message/) ? print "ok 3\n" : print "not ok 3\n";


$Petal::INPUT = 'HTML';
$template_file = 'if.html';
$template = new Petal ($template_file); 

($template->process =~ /\<p\>/) ? print "not ok 4\n" : print "ok 4\n";
($template->process (error => 'Some error message') =~ /Some error message/) ? print "ok 5\n" : print "not ok 5\n";
