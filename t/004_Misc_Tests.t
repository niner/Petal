use lib ('lib');
use Test;

BEGIN {print "1..2\n";}
END {print "not ok 1\n" unless $loaded;}
use Petal;
use vars qw /$loaded/;
$loaded = 1;
print "ok 1\n";

my $template_file = 'test.tmpl';
my $template = new Petal ( base_dir => './t/data/multiple_includes/',
	file => $template_file,
	disk_cache => 0,
	memory_cache => 0,
	taint => 1,
);

$Petal::PARSER = 'HTML';

my $hash = {
	first_name => "William",
	last_name => "McKee",
	email => 'william@knowmad.com',
};

($template->process ($hash) =~ /william\@knowmad.com/sm) ? print "ok 2\n" : print "not ok 2\n";
