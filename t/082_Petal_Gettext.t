#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';
use Petal::I18N;
use Petal;

eval "use Locale::Maketext::Gettext";
if ($@) {
   warn "Locale::Maketext::Gettext not found - skipping";
   ok (1);
}
else {
    eval "use Petal::TranslationService::MOFile";
    $@ and die $@;

    my $lh = Locale::Maketext::Gettext->get_handle();
    my %lexicon = read_mo ('./t/data/gettext/mo/fr.mo');
    ok ( $lexicon{'you-are-user'} );
    ok ( $lexicon{'hello-this-is-a-test'} );

    my $ts = Petal::TranslationService::MOFile->new ('./t/data/gettext/mo/en.mo');
    my $t = new Petal ( file => './t/data/gettext/html/index.html',
                        disk_cache => 0,
                        memory_cache => 0,
                        translation_service => $ts );


    my $res = $t->process( user_name => 'becky');
    like ($res, qr/Hello, this is a test/);
    like ($res, qr/You are user \<span\>becky\<\/span\>/);
    like ($res, qr/a search engine/);

    $ts = Petal::TranslationService::MOFile->new ('./t/data/gettext/mo/fr.mo');
    ok ($ts->maketext ('you-are-user'));
    ok ($ts->maketext ('hello-this-is-a-test'));

    $t = new Petal ( file => './t/data/gettext/html/index.html',
                     disk_cache => 0,
                     memory_cache => 0,
                     translation_service => $ts );
    $res = $t->process ( user_name => 'becky');
    like ($res, qr/Bonjour, ceci est un test/);
}


1;


__END__
