#!/usr/bin/perl
use Test::More 'no_plan';
use warnings;
use lib 'lib';
use Petal;

$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::BASE_DIR = ('t/data');
my $file     = 'metal_define_macro.xml';

{
    my $t = new Petal ( file => 'metal_define_macro.xml' );
    my $s = $t->process();
    like ($s, qr/<test>Foo<\/test>/);
    like ($s, qr/<test>Bar<\/test>/);
    like ($s, qr/<test>Baz<\/test>/);
}

{
    my $t = new Petal ( file => 'metal_define_macro.xml#foo' );
    my $s = $t->process();
    like ($s, qr/<test>Foo<\/test>/);
    unlike ($s, qr/<test>Bar<\/test>/);
    unlike ($s, qr/<test>Baz<\/test>/);
}

{
    my $t = new Petal ( file => 'metal_define_macro.xml#bar' );
    my $s = $t->process();
    unlike ($s, qr/<test>Foo<\/test>/);
    like ($s, qr/<test>Bar<\/test>/);
    unlike ($s, qr/<test>Baz<\/test>/);
}

{
    my $t = new Petal ( file => 'metal_define_macro.xml#baz' );
    my $s = $t->process();
    unlike ($s, qr/<test>Foo<\/test>/);
    unlike ($s, qr/<test>Bar<\/test>/);
    like ($s, qr/<test>Baz<\/test>/);
}

