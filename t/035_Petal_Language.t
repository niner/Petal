package main;
use warnings;
use lib ('lib');
use Petal::Functions;
use Petal;


BEGIN {print "1..8\n";}
END {print "not ok 1\n" unless $loaded;}
use Petal;
$loaded = 1;
print "ok 1\n";

use strict;
my $loaded = 1;

$|=1;


# exists_filename tests
{
    my $filename;
    
    $filename = Petal::Functions::exists_filename ('fr-CA' => './t/data/language/exists_filename/');
    ($filename eq 'fr-CA.html') ? print "ok 2\n" : print "not ok 2\n";


    $filename = Petal::Functions::exists_filename ('fr'    => './t/data/language/exists_filename/');
    ($filename eq 'fr.xml') ? print "ok 3\n" : print "not ok 3\n";
    
    $filename = Petal::Functions::exists_filename ('en'    => './t/data/language/exists_filename/');
    (defined $filename) ? print "not ok 4\n" : print "ok 4\n";
}


# parent_language
{
    my $lang = 'fr-CA';
    $lang = Petal::Functions::parent_language ($lang);
    ($lang eq 'fr') ? print "ok 5\n" : print "not ok 5\n";
    
    $lang = Petal::Functions::parent_language ($lang);
    ($lang eq 'en') ? print "ok 6\n" : print "not ok 6\n";

    $lang = Petal::Functions::parent_language ($lang);
    (defined $lang) ? print "not ok 7\n" : print "ok 7\n";
}


{
    local $Petal::INPUT    = 'XML';
    local $Petal::OUTPUT   = 'XML';
    local $Petal::BASE_DIR = 't/data/language';
    my $template = new Petal ( file => '.', lang => 'fr-CA');
    ($template->process() =~ /fr\-CA/) ? print "ok 8\n" : print "not ok 8\n";
}


__END__
