#!/usr/bin/perl
#
package main;
use warnings;
use lib ('lib');

use Test::More qw( no_plan );
use Petal;

$|=1;

$Petal::BASE_DIR     = './t/data/';
$Petal::DISK_CACHE   = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT        = 1;
$Petal::INPUT        = "XML";
$Petal::OUTPUT       = "XML";

my $template_file = 'eval.xml';
my $template      = new Petal ($template_file);
my $string        = $template->process;

like( $string, qr/should\s+appear/, 'should appear (XML out)' );
like( $string, qr/booo/,            'booo (XML out)' );
unlike( $string, qr/should\s+not\s+appear/, 'should not appear (XML out)' );

$Petal::OUTPUT = "HTML";
$string = $template->process;
like( $string, qr/should\s+appear/, 'should appear (HTML out)' );
like( $string, qr/booo/,            'booo (HTML out)' );
unlike( $string, qr/should\s+not\s+appear/, 'should not appear (HTML out)' );


__END__
