#!/usr/bin/perl
#
package main;
use lib ('lib');
use Test;

BEGIN {print "1..3\n";}
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
	    'array_of_nums'      => [1,2,3,4,],
	    'array_of_chars'     => [qw/ a b c /],
);

eval { $template->process(%hash) };
(defined $@ and $@) ? print "not ok 2\n" : print "ok 2\n";
# print $template->process (%hash);


$Petal::INPUT = "XML";
eval { $template->process(%hash) };
(defined $@ and $@) ? print "not ok 3\n" : print "ok 3\n";
