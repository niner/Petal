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

my $template_file = 'hashref_list.html';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;
$Petal::BASE_DIR = 't/data';
$Petal::INPUT = "HTML";
$Petal::OUTPUT = "XHTML";
my $template = new Petal ($template_file);

my %hash = ();
$hash{'fields'} = [
    { 'name' => 'field1', 'value' => 'value1' },
    { 'name' => 'field2', 'value' => 'value2' },
];


eval { $template->process(%hash) };
(defined $@ and $@) ? print "not ok 2\n" : print "ok 2\n";
# print $template->process (%hash);


$Petal::INPUT = "XML";
eval { $template->process(%hash) };
(defined $@ and $@) ? print "not ok 3\n" : print "ok 3\n";
