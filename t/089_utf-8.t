#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';
use Petal;

$Petal::BASE_DIR = './t/data/';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;

my $template = new Petal (file => 'utf-8.xml', decode_charset => 'utf-8');
my $string   = $template->process;
my $copy     = chr (169);
my $acirc    = chr (194);

like   ($string, qr/$copy/);
unlike ($string, qr/$acirc/);
