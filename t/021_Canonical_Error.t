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

my $template_file = 'canonical_error.html';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;
$Petal::BASE_DIR = 't/data';
$Petal::INPUT = "XML";
$Petal::OUTPUT = "XML";
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

eval { $template->process($hash) };
(defined $@ and $@) ? print "not ok 2\n" : print "ok 2\n";

$Petal::INPUT = "HTML";
$Petal::OUTPUT = "XML";

eval { $template->process($hash) };
(defined $@ and $@) ? print "not ok 3\n" : print "ok 3\n";


$Petal::INPUT = "XML";
$Petal::OUTPUT = "HTML";

eval { $template->process($hash) };
(defined $@ and $@) ? print "not ok 4\n" : print "ok 4\n";


$Petal::INPUT = "HTML";
$Petal::OUTPUT = "HTML";

eval { $template->process($hash) };
(defined $@ and $@) ? print "not ok 5\n" : print "ok 5\n";
