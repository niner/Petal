#!/usr/bin/perl
use Test::More 'no_plan';
use warnings;
use lib 'lib';
use Petal;
use URI;

$Petal::DISK_CACHE   = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::HTML_ERRORS  = 1;
$Petal::BASE_DIR     = ('t/data');
my $file             = 'content_encoded.html';

{
    my $t = new Petal ( file => $file );
    my $s = $t->process ( test => URI->new ('http://example.com/test.cgi?foo=test&bar=test') );
    like ($s, qr/\&amp\;/);
}
