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

#use Petal::TranslationService::h4x0r;
#$Petal::TranslationService = Petal::TranslationService::h4x0r->new();

my $template = new Petal (file => 'dollarone-again.xml');
my $string   = $template->process;
my $res = Petal::I18N->process ($string);

TODO: {
local $TODO = 'shouldn\'t output internal ${1} representation';

unlike ($res, '/\$\{1\}/');
};

