#!C:/perl/bin/perl -w
use warnings;
use lib ('lib');
use Test::More tests => 5;

use Petal;
pass("loaded");

use strict;

#$SIG{__WARN__} = \&Carp::confess;

$|=1;

$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;
$Petal::BASE_DIR = './t/data';

my $template;
my $string;



#####

{
    $Petal::INPUT = "XML";
    $Petal::OUTPUT = "XML";
    $template = new Petal ('test_attributes2.xml');
    
    $string = $template->process(); 
    unlike($string, '/\\\\;/');
}


{
    $Petal::INPUT = "XML";
    $Petal::OUTPUT = "XHTML";
    $template = new Petal ('test_attributes2.xml');

    $string = $template->process(); 
    unlike($string, '/\\\\;/');
}

{
    $Petal::INPUT = "XHTML";
    $Petal::OUTPUT = "XML";
    $template = new Petal ('test_attributes2.xml');
    
    $string = $template->process(); 
    unlike($string, '/\\\\;/');
}

{
    $Petal::INPUT = "XHTML";
    $Petal::OUTPUT = "XHTML";
    $template = new Petal ('test_attributes2.xml');
    
    $string = $template->process(); 
    unlike($string, '/\\\\;/');
}


__END__
