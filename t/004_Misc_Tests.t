use lib ('lib');
use Test;

BEGIN {print "1..4\n";}
END {print "not ok 1\n" unless $loaded;}
use Petal;
use vars qw /$loaded/;
$loaded = 1;
print "ok 1\n";

$Petal::BASE_DIR = './t/data/multiple_includes/';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;

my $template_file = 'test.tmpl';
my $template = new Petal ($template_file);

$Petal::INPUT = 'HTML';

my $hash = {
	first_name => "William",
	last_name => "McKee",
	last => "Boo",
	email => 'william@knowmad.com',
};

($template->process ($hash) =~ /william\@knowmad.com/sm) ? print "ok 2\n" : print "not ok 2\n";
($template->process ($hash) =~ /Boo/) ? print "not ok 3\n" : print "ok 3\n";
($template->process ($hash) =~ /McKee_opposite/) ? print "not ok 4\n" : print "ok 4\n";
