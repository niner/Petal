#!C:/perl/bin/perl -w
use warnings;
use lib ('lib');
use Test;

BEGIN {print "1..18\n";}
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
$Petal::BASE_DIR = './t/data/test_ns_attributes/';

my $template;


$Petal::INPUT = "XML";
$Petal::OUTPUT = "XML";


#####

$Petal::NS = "petal";
$template = new Petal('test_rightWayOfDoing.xml');

my $string = $template->process (baz_value => 'baz_value');
$loaded++;
($string =~ /baz_value/) ? print "ok $loaded\n" : print "not ok $loaded\n";


#####

$Petal::NS = "petal";
$template = new Petal('test_ns_attributes1.xml');

$string = $template->process (
    baz_value  => 'Replaced baz',
    buzz_value => 'Replaced buzz'
   );

$loaded++;
($string =~ /Replaced baz/) ? print "ok $loaded\n" : print "not ok $loaded\n";
$loaded++;
($string =~ /Replaced buzz/) ? print "ok $loaded\n" : print "not ok $loaded\n";


#####

$template = new Petal('test_ns_attributes2.xml');
$string =  $template->process(
    baz_value  => 'Replaced baz',
    buzz_value => 'Replaced buzz'
   );

$loaded++;
($string =~ /Replaced baz/) ? print "ok $loaded\n" : print "not ok $loaded\n";
$loaded++;
($string =~ /Replaced buzz/) ? print "ok $loaded\n" : print "not ok $loaded\n";


#####

$Petal::NS = "petal-temp";
$template = new Petal('test_ns_attributes3.xml');
$string = $template->process (
    baz_value  => 'Replaced baz',
    buzz_value => 'Replaced buzz'
   );

$loaded++;
($string =~ /Replaced baz/) ? print "ok $loaded\n" : print "not ok $loaded\n";
$loaded++;
($string =~ /Replaced buzz/) ? print "ok $loaded\n" : print "not ok $loaded\n";


#####
$Petal::NS = "petal_temp";
$Petal::NS_URI = "urn:pepsdesign.com:petal:temp";
$template = new Petal('test_ns_attributes4.xml');
$string = $template->process(baz_value => 'baz_value');
$loaded++;
($string =~ /baz_value/) ? print "ok $loaded\n" : print "not ok $loaded\n";


#####
$Petal::NS = "petal-temp";
$Petal::NS_URI = "urn:pepsdesign.com:petal:temp";
$template = new Petal('test_ns_attributes5.xml');
$string = $template->process(baz_value => 'baz_value');
$loaded++;
($string =~ /baz_value/) ? print "ok $loaded\n" : print "not ok $loaded\n";


# Replacing multiple attributes...
$Petal::NS = "petal_temp";
$Petal::NS_URI = "urn:pepsdesign.com:petal:temp";
$template = new Petal('test_ns_attributes6.xml');
$string = $template->process (
    baz_data  => 'baz_value',
    buzz_data => 'buzz_value',
    quxx_data => 'quxx_value',
    SC        => ';'
   );
$loaded++;
($string =~ /baz_value/) ? print "ok $loaded\n" : print "not ok $loaded\n";
$loaded++;
($string =~ /buzz_value/) ? print "ok $loaded\n" : print "not ok $loaded\n";
$loaded++;
($string =~ /quxx_value/) ? print "ok $loaded\n" : print "not ok $loaded\n";
$loaded++;
($string =~ /;/) ? print "ok $loaded\n" : print "not ok $loaded\n";


# Replacing multiple attributes...
$Petal::NS = "petal-temp";
$Petal::NS_URI = "urn:pepsdesign.com:petal:temp";
$template = new Petal('test_ns_attributes7.xml');
$string = $template->process (
    baz_data  => 'baz_value',
    buzz_data => 'buzz_value',
    quxx_data => 'quxx_value',
    SC        => ';'
   );
$loaded++;
($string =~ /baz_value/) ? print "ok $loaded\n" : print "not ok $loaded\n";
$loaded++;
($string =~ /buzz_value/) ? print "ok $loaded\n" : print "not ok $loaded\n";
$loaded++;
($string =~ /quxx_value/) ? print "ok $loaded\n" : print "not ok $loaded\n";
$loaded++;
($string =~ /;/) ? print "ok $loaded\n" : print "not ok $loaded\n";


1;


__END__
