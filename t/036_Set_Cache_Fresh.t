#!/usr/bin/perl
package main;
use warnings;
use lib ('lib');
use Test;

BEGIN {print "1..2\n";}
END {print "not ok 1\n" unless $loaded;}
use Petal;
use CGI;
$loaded = 1;
print "ok 1\n";

my $template_file = 'set_cache_fresh.xml';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;
$Petal::BASE_DIR = 't/data';
$Petal::INPUT = "XML";
$Petal::OUTPUT = "XML";
my $template = new Petal ($template_file);

$template->process() =~ /hello/ ? print "ok 2\n" : print "not ok 2\n";
