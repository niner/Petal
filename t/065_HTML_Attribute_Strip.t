#!/usr/bin/perl
use Test::More 'no_plan';
use warnings;
use lib 'lib';
use Petal;

$Petal::DISK_CACHE   = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::BASE_DIR     = ('t/data');
my $file             = 'attribute_strip.html';

{
    my $t = new Petal ( file => $file );
    my $s = $t->process();
    like ($s, qr/test/);
}


{
    my $file  = 'attribute_strip2.html';
    my $t = new Petal ( file => $file );
    my $s = $t->process();
    like ($s, qr/Keyword\(s\)/);
}

$Petal::OUTPUT = 'XHTML';
{
    my $t = new Petal ( file => $file );
    my $s = $t->process();
    like ($s, qr/test/);
}

