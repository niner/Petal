#!/usr/bin/perl
#
package main;
use warnings;
use lib ('lib');
use Test;

BEGIN {print "1..3\n";}
END {print "not ok 1\n" unless $loaded;}
use Petal;
$loaded = 1;
print "ok 1\n";

my $template_file = 'string_count.html';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;
$Petal::BASE_DIR = 't/data';
$Petal::INPUT = "HTML";
$Petal::OUTPUT = "XHTML";
my $template = new Petal ($template_file);

my $hash = {
	error_message => "Kilroy was Here",
	first_name => "William",
	last_name => "McKee",
	email => 'william@knowmad.com',
	students => [ { student_id => '1',
					first_name => 'William',
					last_name => 'McKee',
					email => 'william@knowmad.com',
					},
				  { student_id => '2',
					  first_name => 'Elizabeth',
					  last_name => 'McKee',
					  email => 'elizabeth@knowmad.com',
					},
				],
};

my $html = $template->process($hash);
($html =~ /1 - William/) ? print "ok 2\n" : print "not ok 2\n";
($html =~ /2 - Elizabeth/) ? print "ok 3\n" : print "not ok 3\n";
