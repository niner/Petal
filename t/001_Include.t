# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use lib ('lib');
use Test;

BEGIN {print "1..4\n";}
END {print "not ok 1\n" unless $loaded;}
use Petal;
$loaded = 1;
print "ok 1\n";


#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

$Petal::BASE_DIR = './t/data/include';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
my $petal = new Petal ('index.xml');

# deprecated
# ($petal->_file_path =~ /\/t\/data\/include$/) ? print "ok 2\n" : (print "not ok 2\n" and exit);
print "ok 2\n";

($petal->process =~ /__INCLUDED__/) ? print "ok 3\n" : print "not ok 3\n";
($petal->process =~ /__INCLUDED__\s+<\/body>/) ? print "not ok 4\n" : print "ok 4\n";

1;


__END__
