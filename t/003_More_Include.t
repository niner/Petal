use lib ('lib');
use Test;

BEGIN {print "1..3\n";}
END {print "not ok 1\n" unless $loaded;}
use Petal;
$loaded = 1;
print "ok 1\n";

my $template_file = 'register_form.tmpl';
my $template = new Petal (
	base_dir => './t/data/multiple_includes',
	file => $template_file,
	disk_cache => 0,
	memory_cache => 0,
	taint => 1,
);


# $template::PARSER does not work, but $Petal::PARSER does!
$Petal::PARSER = 'HTML';
($Petal::PARSER eq 'HTML') ? print "ok 2\n" : print "not ok 2\n";

my $data_ref = $template->_file_data_ref;
$data_ref  = $template->_canonicalize;
my @count = $$data_ref =~ /(petal\:include)/gsm;
(scalar @count > 1) ? print "ok 3\n" : print "not ok 3\n";
