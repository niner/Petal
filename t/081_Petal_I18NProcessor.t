#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';
use Petal::I18N;
use Petal;

eval { use Lingua::31337 };
if ($@) {
   # no h4x0r module, no worries...   
   ok (1);
}
else
{
    eval { use Petal::TranslationService::h4x0r };
    die $@ if ($@);

    $Petal::TranslationService = Petal::TranslationService::h4x0r->new();
    my $xml = <<EOF;
<div i18n:translate="test">
  Konichiwa, <span i18n:name="name">Buruno-san</span>,
  Kyoo wa o-genki desu ka?
</div>
EOF

    $xml =~ s/\s*$//;
    print Petal::I18N->process ($xml);
}


1;


__END__
