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

my $template_file = 'autoload.xml';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;
$Petal::BASE_DIR = 't/data';
$Petal::INPUT = "XML";
$Petal::OUTPUT = "XML";
my $template = new Petal ($template_file);

my $res = undef;
eval { $res = $template->process ( cgi => new CGI ) };
(defined $@ and $@) ? print "not ok 2\n" : print "ok 2\n";

($res !~ /input/si) ? print "not ok 3\n" : print "ok 3\n";
