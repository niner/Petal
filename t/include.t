# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use lib ('lib');
use Test;

BEGIN {print "1..2\n";}
END {print "not ok 1\n" unless $loaded;}
use Petal;
$loaded = 1;
print "ok 1\n";


#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

my $petal = new Petal ( base_dir => './t/data', file => 'include/master.xml' );

($petal->_base_dir =~ /\/t\/data$/) ? print "ok 2\n" : print "not ok 2\n" and exit;

1;


__END__
