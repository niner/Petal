#!/usr/bin/perl
package main;
use lib ('lib');
use Test;

BEGIN {print "1..3\n";}
END {print "not ok 1\n" unless $loaded;}
use Petal;
use CGI;
$loaded = 1;
print "ok 1\n";

my $template_file = 'split_expression.xml';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;
$Petal::BASE_DIR = 't/data';
$Petal::INPUT = "XML";
$Petal::OUTPUT = "XML";
my $template = new Petal ($template_file);

($template->process (foo => 1, bar => 1) =~ /Hello/) ? print "ok 2\n" : print "not ok 2\n";

$Petal::INPUT = "XML";
($template->process (foo => 1, bar => 1) =~ /Hello/) ? print "ok 3\n" : print "not ok 3\n";
