package Petal::TranslationService::MOFile;
use Locale::Maketext::Gettext;
use strict;
use warnings;


sub new
{
    my $class = shift;
    my $file  = shift || do {
        warn "No file specified for " . __PACKAGE__ . "::new (\$file)";
        return bless {}, $class;
    };

    -e $file or do { 
        warn "$file does not seem to exist";
        return bless {}, $class;
    };

    -f $file or do {
        warn "$file does not seem to be a file";
        return bless {}, $class;
    };

    my $self = bless { file => $file }, $class;
    $self->{lexicon} = { read_mo ($file) };
    return $self;
}


sub maketext
{
    my $self = shift;
    my $id   = shift || return;
    $self->{lexicon} || return;
    return $self->{lexicon}->{$id};
}


1;


__END__
