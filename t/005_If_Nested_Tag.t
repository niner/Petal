use lib ('lib');
use Test;

BEGIN {print "1..5\n";}
END {print "not ok 1\n" unless $loaded;}
use Petal;
$loaded = 1;
print "ok 1\n";

my $template_file = 'if.xml';
my $template = new Petal (
	base_dir => './t/data',
	file => $template_file,
	disk_cache => 0,
	memory_cache => 0,
	taint => 1,
);


($template->process =~ /\<p\>/) ? print "not ok 2\n" : print "ok 2\n";
($template->process (error => 'Some error message') =~ /Some error message/) ? print "ok 3\n" : print "not ok 3\n";


$Petal::PARSER = 'HTML';
$template_file = 'if.html';
$template = new Petal (
	base_dir => './t/data',
	file => $template_file,
	disk_cache => 0,
	memory_cache => 0,
	taint => 1,
);


($template->process =~ /\<p\>/) ? print "not ok 4\n" : print "ok 4\n";
($template->process (error => 'Some error message') =~ /Some error message/) ? print "ok 5\n" : print "not ok 5\n";
