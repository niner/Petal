#!/usr/bin/perl

##
## Test errors when trying to access undefined variables
##

use warnings;
use lib 'lib';

use Test::More qw( no_plan );
use Petal;

$Petal::BASE_DIR     = './t/data/';
$Petal::DISK_CACHE   = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT        = 1;
$Petal::INPUT        = 'HTML';

my $foo  = bless {}, 'Foo';
my $tmpl = Petal->new( 'error_on_undef_var.html' );

# normal operation:
{
    eval { $tmpl->process( foo => $foo ); };
    ok( $@, 'error thrown on undef var' );
}

# errors turned off:
{
    local $Petal::Hash::Var::ERROR_ON_UNDEF_VAR = 0;
    eval {
	my $string = $tmpl->process( foo => $foo );
	unlike( $string, qr/ok: bar/, 'did not access [bar] var in [foo]' );
    };
    if ($@) {
	fail('error thrown on undef var (errors turned off)');
	diag($@);
    }
}

