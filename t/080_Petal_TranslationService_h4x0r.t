#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';

eval { use Lingua::31337 };
if ($@) {
   # no h4x0r module, no worries...   
   ok (1);
}
else
{
   eval { use Petal::TranslationService::h4x0r };
   die $@ if ($@);

   my $trans  = new Petal::TranslationService::h4x0r;
   ok ($trans->isa ('Petal::TranslationService::h4x0r'));

   my $string = 'Adam, Bruno, Chris';
   my $res = $trans->get_from_string ($string);
   ok ($res ne $string);
}


1;


__END__
