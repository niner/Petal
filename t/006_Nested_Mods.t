use lib ('lib');
use Test;

BEGIN {print "1..4\n";}
END {print "not ok 1\n" unless $loaded;}
use Petal;
$loaded = 1;
print "ok 1\n";

$Petal::BASE_DIR = './t/data/nested_modifiers';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;
my $template_file = 'test1.xml';
my $template = new Petal ($template_file);

(${$template->_canonicalize} =~ /uc:string/) ? print "ok 2\n" : print "not ok 2\n";
($template->process ( string => "foo & bar + baz" ) =~ /FOO/) ? print "ok 3\n" : print "not ok 3\n";


$template_file = 'test2.xml';
$template = new Petal ($template_file);

($template->process ( string => "foo & bar + baz" ) =~ /FOO \&amp;/) ? print "ok 4\n" : print "not ok 4\n";
