#!C:/perl/bin/perl -w
package SomeObject;

sub list { [ 1, 2, 3, 4 ] }

sub as_string { 'Haro Genki' }


package main;
use warnings;
use lib ('lib');
use Test;


BEGIN {print "1..3\n";}
END {print "not ok 1\n" unless $loaded;}
use Petal;
$loaded = 1;
print "ok 1\n";

use strict;
my $loaded = 1;

$|=1;

$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;
$Petal::BASE_DIR = './t/data';

my $template;
my $string;


$Petal::INPUT = "XML";
$Petal::OUTPUT = "XML";

eval {
    $template = new Petal ('hash_mustpass.xml');
    my $object = bless {}, 'SomeObject';
    $string = $template->process (object => $object);
};
$loaded++;
(defined $@ and $@) ? print "not ok $loaded\n" : print "ok $loaded\n";


eval {
    $template = new Petal ('hash_mustfail.xml');
    my $object = bless {}, 'SomeObject';
    $string = $template->process (object => $object);
};
$loaded++;
(defined $@ and $@) ? print "ok $loaded\n" : print "not ok $loaded\n";


__END__
