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

use File::Spec;
my $tmp_dir = File::Spec->tmpdir;
if (defined $tmp_dir)
{
    print "ok 2\n";
}
else
{
    print "not ok 2\n";
    exit;
}


my $tmp_file = join '', map { chr (ord ('a') + int rand (26)) } 1..8;
$tmp_file .= ".$$.tmp";

open FP, ">$tmp_dir/$tmp_file" or do {
    print "not ok 3\n";
    exit;
};

print "ok 3\n";
print FP <<'END';
<html>
<body>
    <?petal:var name=":set settest title"?>

    * title : $title
    * settest : $settest
</body>
</html>
END

close FP;

$Petal::PARSER = 'HTML';
my $petal = new Petal (
    base_dir => $tmp_dir,
    file => $tmp_file,
    no_memory_cache => 1,
    no_disk_cache => 1
   );

my $res = $petal->process (
    title => '__TAG__',
    settest => 'blah'
);

# test that we have __TAG__ twice
my @capture = ($res =~ /(__TAG__)/g);
(scalar @capture == 2) ? print "ok 4\n" : print "not ok 4\n";

# clean up the mess
unlink "$tmp_dir/$tmp_file";


1;


__END__
