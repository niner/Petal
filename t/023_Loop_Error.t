#!/usr/bin/perl
#
package main;
use lib ('lib');
use Test;

BEGIN {print "1..4\n";}
END {print "not ok 1\n" unless $loaded;}
use Petal;
$loaded = 1;
print "ok 1\n";

my $template_file = 'loop_error.xml';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;
$Petal::BASE_DIR = 't/data';
$Petal::INPUT = "HTML";
$Petal::OUTPUT = "XHTML";
my $template = new Petal ($template_file);

my %hash = (
	    'array_of_nums'      => [1,2,3,],
	    'array_of_chars'     => [qw/ a b c /],
	    'array_of_stuff'     => [qw/ ! @ # /],
	    'array_of_nums2'     => [9,8,7,],
	    'array_of_chars2'    => [qw/ x y z /],
	    'array_of_stuff2'    => [qw/ $ % ^ /],
	    'array_of_nums3'     => [4,5,6,],
	    'array_of_chars3'    => [qw/ g h i /],
	    'array_of_stuff3'    => [qw/ & * | /],
);

my $str = undef;
eval { $str = $template->process(%hash) };
# print STDERR $str;

# shouldn't be any "num=[...]" that don't have numbers inside
($str !~ /num=\[\D+\]/) ? print "ok 2\n" : print "not ok 2\n";

# shouldn't be any "chr=[...]" that don't have chars inside
($str !~ /chr=\[\W+\]/) ? print "ok 3\n" : print "not ok 3\n";

# shouldn't be any "stf=[...]" that don't have 'stuff' inside
($str !~ /stf=\[[^\W]+\]/) ? print "ok 4\n" : print "not ok 4\n";
