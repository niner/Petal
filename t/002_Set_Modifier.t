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

$Petal::BASE_DIR = './t/data/set_modifier';
$Petal::MEMORY_CACHE = 0;
$Petal::DISK_CACHE   = 0;

my $petal = new Petal ('index.xml');

my $res = $petal->process (
    title => '__TAG__',
    settest => 'blah'
);


# test that we have __TAG__ twice
my @capture = ($res =~ /(__TAG__)/g);
(scalar @capture == 2) ? print "ok 2\n" : print "not ok 2\n";


1;


__END__
