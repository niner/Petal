#!/usr/bin/perl
#
package main;
use warnings;
use lib ('lib');
use Test;

BEGIN {print "1..8\n";}
END {print "not ok 1\n" unless $loaded;}
use Petal;
$loaded = 1;
print "ok 1\n";


my $template_file = 'omit-tag.xml';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;
$Petal::BASE_DIR = 't/data';
$Petal::INPUT = "XML";
$Petal::OUTPUT = "XML";

my $template = new Petal ($template_file);
my $string = $template->process();
($string =~ /<b>This tag should not be omited/) ? print "ok 2\n" : print "not ok 2\n";
($string !~ /<b>This tag should be omited/) ? print "ok 3\n" : print "not ok 3\n";

$Petal::OUTPUT = "XHTML";
$string = $template->process();

($string =~ /<b>This tag should not be omited/) ? print "ok 4\n" : print "not ok 4\n";
($string !~ /<b>This tag should be omited/) ? print "ok 5\n" : print "not ok 5\n";

$Petal::INPUT = "XML";
$Petal::OUTPUT = "XHTML";
$template_file = 'xhtml_omit_tag.html';
$template = new Petal ($template_file);
my $data = $template->process(
    content => "What's up with the closing tags below?"
   );

($data =~ /<html>/) ? print "not ok 6\n" : print "ok 6\n";
($data =~ /<body>/) ? print "not ok 7\n" : print "ok 7\n";
($data =~ /<p>What/) ? print "ok 8\n" : print "not ok 8\n";


1;
