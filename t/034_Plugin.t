package main;
use warnings;
use lib ('lib');
use Test::More tests => 2;


use Petal;
pass("loaded");

use strict;
my $loaded = 1;

$|=1;

$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;
$Petal::BASE_DIR = './t/data';
$Petal::INPUT = "XML";
$Petal::OUTPUT = "XML";

my $template = new Petal ('plugin.xml');

my $str = $template->process();
like($str, '/HELLO, WORLD/', "matches");

__END__
