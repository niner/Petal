#!C:/perl/bin/perl -w
use warnings;
use lib ('lib');
use Test::More tests => 20;

END {fail("loaded") unless $loaded;}
use Petal;
$loaded = 1;
pass("loaded");

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
    
    $string = ${$template->_canonicalize()};
    unlike($string, '/""/');
}


{
    $Petal::INPUT = "XML";
    $Petal::OUTPUT = "XHTML";
    $template = new Petal ('attributes_andquot.xml');
    
    $string = ${$template->_canonicalize()};
    unlike($string, '/""/');
}


{
    $Petal::INPUT = "XHTML";
    $Petal::OUTPUT = "XML";
    $template = new Petal ('attributes_andquot.xml');
    
    $string = ${$template->_canonicalize()};
    unlike($string, '/""/');
}


{
    $Petal::INPUT = "XHTML";
    $Petal::OUTPUT = "XHTML";
    $template = new Petal ('attributes_andquot.xml');
    
    $string = ${$template->_canonicalize()};
    unlike($string, '/""/');
}


{
    $Petal::INPUT = "XML";
    $Petal::OUTPUT = "XML";
    $template = new Petal ('inline_vars.xml');
    $string = ${$template->_canonicalize()};
    
    like($string, '/&quot;/');
    
    like($string, '/\<\?/');
    
    like($string, '/\?\>/');
}


{
    $Petal::INPUT = "XML";
    $Petal::OUTPUT = "XHTML";
    $template = new Petal ('inline_vars.xml');
    $string = ${$template->_canonicalize()};

    like($string, '/&quot;/');
    
    like($string, '/<\?/');
    
    like($string, '/\?>/');
}


{
    $Petal::INPUT = "XHTML";
    $Petal::OUTPUT = "XML";
    $template = new Petal ('inline_vars.xml');
    $string = ${$template->_canonicalize()};

    like($string, '/&quot;/');
    
    like($string, '/<\?/');
    
    like($string, '/\?>/');
}


{
    $Petal::INPUT = "XHTML";
    $Petal::OUTPUT = "XHTML";
    $template = new Petal ('inline_vars.xml');
    $string = ${$template->_canonicalize()};

    like($string, '/&quot;/');
    
    like($string, '/<\?/');
    
    like($string, '/\?>/');
}

JUMP:
{
    $Petal::INPUT = "XML";
    $Petal::OUTPUT = "XML";
    $template = new Petal ('manipulate.html');
    
    $string = $template->process (
	configuration => { get_identity_field_name => 'id' }
       );

    like($string, '/petal:attributes="value entry\/id;"/');
    
    like($string, '/type="hidden"/');
    
    like($string, '/name="id"/');
}

1;


__END__
