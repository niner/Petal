#!/usr/bin/perl
#
package main;
use warnings;
use lib ('lib');
use Test::More tests => 9;

END {fail("loaded") unless $loaded;}
use Petal;
$loaded = 1;
pass("loaded");


my $template_file = 'omit-tag.xml';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;
$Petal::BASE_DIR = 't/data';
$Petal::INPUT = "XML";
$Petal::OUTPUT = "XML";

my $template = new Petal ($template_file);
my $string = $template->process();
like($string, '/<b>This tag should not be omited/', "XML - XML preserve");
unlike($string, '/<b>This tag should be omited/', "XML - XML omit");

$Petal::OUTPUT = "XHTML";
$string = $template->process();

like($string, '/<b>This tag should not be omited/', "XML - XHTML preserve");
unlike($string, '/<b>This tag should be omited/', "XML - XHTML omit");

$Petal::INPUT = "XML";
$Petal::OUTPUT = "XHTML";
$template_file = 'xhtml_omit_tag.html';
$template = new Petal ($template_file);
my $data = $template->process(
    content => "What's up with the closing tags below?"
   );

unlike($data, '/<html>/');
unlike($data, '/<body>/');
like($data, '/<p>What/');

unlike ($data, qr/<b>Is this a bug/ => 'omit-tag=""');

1;
