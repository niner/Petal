#!/usr/bin/perl
#
package main;
use lib ('lib');
use Test;

BEGIN {print "1..5\n";}
END {print "not ok 1\n" unless $loaded;}
use Petal;
$loaded = 1;
print "ok 1\n";

my $template_file = 'eval.xml';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;
$Petal::BASE_DIR = 't/data';
$Petal::INPUT = "XML";
$Petal::OUTPUT = "XML";

my $template = new Petal ($template_file);

my $string = $template->process;
$string =~ /should\s+appear/ ? print "ok 2\n" : print "not ok 2\n";
$string =~ /booo/ ? print "ok 3\n" : print "not ok 3\n";

$Petal::OUTPUT = "HTML";
$string = $template->process;
$string =~ /should\s+appear/ ? print "ok 4\n" : print "not ok 4\n";
$string =~ /booo/ ? print "ok 5\n" : print "not ok 5\n";
