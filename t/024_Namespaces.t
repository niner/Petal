#!/usr/bin/perl
#
package main;
use lib ('lib');
use Test;

BEGIN {print "1..33\n";}
END {print "not ok 1\n" unless $loaded;}
use Petal;
$loaded = 1;
print "ok 1\n";

my $template_file = 'namespaces.xml';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;
$Petal::BASE_DIR = 't/data';
my $template = new Petal ($template_file);
my $string;


#   input: XML
#   output: XML
$Petal::INPUT = "XML";
$Petal::OUTPUT = "XML";
$string = $template->process (
	replace   => 'REPLACE',
	content   => 'CONTENT',
	attribute => 'ATTRIBUTE',
        elements  => [ 'ELEMENT1', 'ELEMENT2', 'ELEMENT3' ],
);

($string =~ /REPLACE/) ? print "ok 2\n" : print "not ok 2\n";
($string =~ /\Q<p>CONTENT<\/p>\E/) ? print "ok 3\n" : print "not ok 3\n";
($string =~ /\Q<p attribute="ATTRIBUTE">yo<\/p>\E/) ? print "ok 4\n" : print "not ok 4\n";
($string =~ /\Q<li>ELEMENT1<\/li>\E/) ? print "ok 5\n" : print "not ok 5\n";
($string =~ /\Q<li>ELEMENT2<\/li>\E/) ? print "ok 6\n" : print "not ok 6\n";
($string =~ /\Q<li>ELEMENT3<\/li>\E/) ? print "ok 7\n" : print "not ok 7\n";
($string !~ /\Qtal:\E/) ? print "ok 8\n" : print "not ok 8\n";
($string !~ /\Qxmlns:\E/) ? print "ok 9\n" : print "not ok 9\n";


#   input: XML
#   output: XHTML
$Petal::INPUT = "XML";
$Petal::OUTPUT = "XHTML";
$string = $template->process (
	replace   => 'REPLACE',
	content   => 'CONTENT',
	attribute => 'ATTRIBUTE',
        elements  => [ 'ELEMENT1', 'ELEMENT2', 'ELEMENT3' ],
);

($string =~ /REPLACE/) ? print "ok 10\n" : print "not ok 10\n";
($string =~ /\Q<p>CONTENT<\/p>\E/) ? print "ok 11\n" : print "not ok 11\n";
($string =~ /\Q<p attribute="ATTRIBUTE">yo<\/p>\E/) ? print "ok 12\n" : print "not ok 12\n";
($string =~ /\Q<li>ELEMENT1<\/li>\E/) ? print "ok 13\n" : print "not ok 13\n";
($string =~ /\Q<li>ELEMENT2<\/li>\E/) ? print "ok 14\n" : print "not ok 14\n";
($string =~ /\Q<li>ELEMENT3<\/li>\E/) ? print "ok 15\n" : print "not ok 15\n";
($string !~ /\Qtal:\E/) ? print "ok 16\n" : print "not ok 16\n";
($string !~ /\Qxmlns:\E/) ? print "ok 17\n" : print "not ok 17\n";


#   input: XHTML
#   output: XML
$Petal::INPUT = "XHTML";
$Petal::OUTPUT = "XML";
$string = $template->process (
	replace   => 'REPLACE',
	content   => 'CONTENT',
	attribute => 'ATTRIBUTE',
        elements  => [ 'ELEMENT1', 'ELEMENT2', 'ELEMENT3' ],
);

($string =~ /REPLACE/) ? print "ok 18\n" : print "not ok 18\n";
($string =~ /\Q<p>CONTENT<\/p>\E/) ? print "ok 19\n" : print "not ok 19\n";
($string =~ /\Q<p attribute="ATTRIBUTE">yo<\/p>\E/) ? print "ok 20\n" : print "not ok 20\n";
($string =~ /\Q<li>ELEMENT1<\/li>\E/) ? print "ok 21\n" : print "not ok 21\n";
($string =~ /\Q<li>ELEMENT2<\/li>\E/) ? print "ok 22\n" : print "not ok 22\n";
($string =~ /\Q<li>ELEMENT3<\/li>\E/) ? print "ok 23\n" : print "not ok 23\n";
($string !~ /\Qtal:\E/) ? print "ok 24\n" : print "not ok 24\n";
($string !~ /\Qxmlns:\E/) ? print "ok 25\n" : print "not ok 25\n";


#   input: XHTML
#   output: XHTML
$Petal::INPUT = "XHTML";
$Petal::OUTPUT = "XHTML";
$string = $template->process (
	replace   => 'REPLACE',
	content   => 'CONTENT',
	attribute => 'ATTRIBUTE',
        elements  => [ 'ELEMENT1', 'ELEMENT2', 'ELEMENT3' ],
);

($string =~ /REPLACE/) ? print "ok 26\n" : print "not ok 26\n";
($string =~ /\Q<p>CONTENT<\/p>\E/) ? print "ok 27\n" : print "not ok 27\n";
($string =~ /\Q<p attribute="ATTRIBUTE">yo<\/p>\E/) ? print "ok 28\n" : print "not ok 28\n";
($string =~ /\Q<li>ELEMENT1<\/li>\E/) ? print "ok 29\n" : print "not ok 29\n";
($string =~ /\Q<li>ELEMENT2<\/li>\E/) ? print "ok 30\n" : print "not ok 30\n";
($string =~ /\Q<li>ELEMENT3<\/li>\E/) ? print "ok 31\n" : print "not ok 31\n";
($string !~ /\Qtal:\E/) ? print "ok 32\n" : print "not ok 32\n";
($string !~ /\Qxmlns:\E/) ? print "ok 33\n" : print "not ok 33\n";
