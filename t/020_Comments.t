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

my $template_file = 'comments.xml';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;
$Petal::BASE_DIR = 't/data';
$Petal::INPUT = "XHTML";
$Petal::OUTPUT = "XML";
my $template = new Petal ($template_file);

($template->process() !~ /^\<\!/) ? print "ok 2\n" : print "not ok 2\n";

$Petal::INPUT = "XML";
($template->process() !~ /^\<\!/) ? print "ok 3\n" : print "not ok 3\n";
