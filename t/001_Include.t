#!/usr/bin/perl
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use warnings;
use lib ('lib');
use Test::More tests => 12;

END {fail("loaded") unless $loaded;}
use Petal;
$loaded = 1;
pass("loaded");

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

$Petal::BASE_DIR = './t/data/include';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;

my $petal = new Petal ('index.xml');
# deprecated
# ($petal->_file_path =~ /\/t\/data\/include$/) ? print "ok 2\n" : (print "not ok 2\n" and exit);
pass();

unlike(${$petal->_canonicalize()}, '/World""/', "canonicalise");
like($petal->process, '/__INCLUDED__/', "find marker");
unlike($petal->process, '/__INCLUDED__\s+<\/body>/', "find marker and tag");
like($petal->process, '/Hello, &quot;World&quot;/', "find hello");

{
    $Petal::INPUT  = "XML";
    $Petal::OUTPUT = "XML";
    $petal = new Petal ('index_xinclude.xml');
    like($petal->process, '/__INCLUDED__/', "XML - XML find included");
    
    $Petal::INPUT  = "XHTML";
    $Petal::OUTPUT = "XML";
    my $petal = new Petal ('index_xinclude.xml');
    like($petal->process, '/__INCLUDED__/', "XHTML - XML find included");
    
    $Petal::INPUT  = "XML";
    $Petal::OUTPUT = "XHTML";
    $petal = new Petal ('index_xinclude.xml');
    like($petal->process, '/__INCLUDED__/', "XML - XHTML find included");
    
    $Petal::INPUT  = "XHTML";
    $Petal::OUTPUT = "XHTML";
    $petal = new Petal ('index_xinclude.xml');
    like($petal->process, '/__INCLUDED__/', "XHTML - XHTML find included");
}

$Petal::BASE_DIR = './t/data/include/deep';
eval {
    $Petal::INPUT  = "XML";
    $Petal::OUTPUT = "XML";
    $petal = new Petal ('index.xml');
    $petal->process;
};
like($@, '/Cannot go above base directory/', "correct error");


$Petal::BASE_DIR = './t/data/include';
{
    $Petal::INPUT  = "XML";
    $Petal::OUTPUT = "XML";
    $petal = new Petal ('deep/index.xml');
    like($petal->process, '/__INCLUDED__/', "deep find included");
}


1;


__END__
