use lib ('lib');
use Test;

BEGIN {print "1..4\n";}
END {print "not ok 1\n" unless $loaded;}
use Petal;
$loaded = 1;
print "ok 1\n";

my $template_file = 'test1.xml';
my $template = new Petal (
    base_dir => './t/data/nested_modifiers',
    file => $template_file,
    disk_cache => 0,
    memory_cache => 0,
    taint => 1,
   );

(${$template->_canonicalize} =~ /uc:string/) ? print "ok 2\n" : print "not ok 2\n";
($template->process ( string => "foo & bar + baz" ) =~ /FOO/) ? print "ok 3\n" : print "not ok 3\n";


$template_file = 'test2.xml';
$template = new Petal (
    base_dir => './t/data/nested_modifiers',
    file => $template_file,
    disk_cache => 0,
    memory_cache => 0,
    taint => 1,
   );

($template->process ( string => "foo & bar + baz" ) =~ /FOO \&amp;/) ? print "ok 4\n" : print "not ok 4\n";
