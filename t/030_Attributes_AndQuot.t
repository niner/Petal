#!C:/perl/bin/perl -w
use warnings;
use lib ('lib');
use Test;

BEGIN {print "1..20\n";}
END {print "not ok 1\n" unless $loaded;}
use Petal;
$loaded = 1;
print "ok 1\n";

use strict;
my $loaded = 1;

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
    $template = new Petal ('attributes_andquot.xml');
    
    $loaded++;
    $string = ${$template->_canonicalize()};
    ($string !~ /\"\"/) ? print "ok $loaded\n" : print "not ok $loaded\n";
}


{
    $Petal::INPUT = "XML";
    $Petal::OUTPUT = "XHTML";
    $template = new Petal ('attributes_andquot.xml');
    
    $loaded++;
    $string = ${$template->_canonicalize()};
    ($string !~ /\"\"/) ? print "ok $loaded\n" : print "not ok $loaded\n";
}


{
    $Petal::INPUT = "XHTML";
    $Petal::OUTPUT = "XML";
    $template = new Petal ('attributes_andquot.xml');
    
    $loaded++;
    $string = ${$template->_canonicalize()};
    ($string !~ /\"\"/) ? print "ok $loaded\n" : print "not ok $loaded\n";
}


{
    $Petal::INPUT = "XHTML";
    $Petal::OUTPUT = "XHTML";
    $template = new Petal ('attributes_andquot.xml');
    
    $loaded++;
    $string = ${$template->_canonicalize()};
    ($string !~ /\"\"/) ? print "ok $loaded\n" : print "not ok $loaded\n";
}


{
    $Petal::INPUT = "XML";
    $Petal::OUTPUT = "XML";
    $template = new Petal ('inline_vars.xml');
    $string = ${$template->_canonicalize()};
    
    $loaded++;
    ($string =~ /\&quot\;/) ? print "ok $loaded\n" : print "not ok $loaded\n";
    
    $loaded++;
    ($string =~ /\<\?/) ? print "ok $loaded\n" : print "not ok $loaded\n";
    
    $loaded++;
    ($string =~ /\?\>/) ? print "ok $loaded\n" : print "not ok $loaded\n";
}


{
    $Petal::INPUT = "XML";
    $Petal::OUTPUT = "XHTML";
    $template = new Petal ('inline_vars.xml');
    $string = ${$template->_canonicalize()};

    $loaded++;
    ($string =~ /\&quot\;/) ? print "ok $loaded\n" : print "not ok $loaded\n";
    
    $loaded++;
    ($string =~ /\<\?/) ? print "ok $loaded\n" : print "not ok $loaded\n";
    
    $loaded++;
    ($string =~ /\?\>/) ? print "ok $loaded\n" : print "not ok $loaded\n";
}


{
    $Petal::INPUT = "XHTML";
    $Petal::OUTPUT = "XML";
    $template = new Petal ('inline_vars.xml');
    $string = ${$template->_canonicalize()};

    $loaded++;
    ($string =~ /\&quot\;/) ? print "ok $loaded\n" : print "not ok $loaded\n";
    
    $loaded++;
    ($string =~ /\<\?/) ? print "ok $loaded\n" : print "not ok $loaded\n";
    
    $loaded++;
    ($string =~ /\?\>/) ? print "ok $loaded\n" : print "not ok $loaded\n";
}


{
    $Petal::INPUT = "XHTML";
    $Petal::OUTPUT = "XHTML";
    $template = new Petal ('inline_vars.xml');
    $string = ${$template->_canonicalize()};

    $loaded++;
    ($string =~ /\&quot\;/) ? print "ok $loaded\n" : print "not ok $loaded\n";
    
    $loaded++;
    ($string =~ /\<\?/) ? print "ok $loaded\n" : print "not ok $loaded\n";
    
    $loaded++;
    ($string =~ /\?\>/) ? print "ok $loaded\n" : print "not ok $loaded\n";
}


{
    $Petal::INPUT = "XML";
    $Petal::OUTPUT = "XML";
    $template = new Petal ('manipulate.html');
    
    $string = $template->process (
	configuration => { get_identity_field_name => 'id' }
       );
    
    $loaded++;
    ($string =~ m!petal:attributes="value entry/id;"!) ? print "ok $loaded\n" : print "not ok $loaded\n";
    
    $loaded++;
    ($string =~ m!type="hidden"!) ? print "ok $loaded\n" : print "not ok $loaded\n";
    
    $loaded++;
    ($string =~ m!name="id"!) ? print "ok $loaded\n" : print "not ok $loaded\n";
}

1;


__END__
