# ------------------------------------------------------------------
# Petal::I18N - Independant I18N processing
# ------------------------------------------------------------------
package Petal::I18N;
use MKDoc::XML::TreeBuilder;
use MKDoc::XML::TreePrinter;
use Petal::Hash::String;
use warnings;
use strict;

our $Namespace = "http://xml.zope.org/namespaces/i18n";
our $Prefix    = 'i18n';
our $Domain    = 'default';


sub process
{
    my $class = shift;
    my $data  = shift;

    local $Namespace = $Namespace;
    local $Prefix    = $Prefix;
    local $Domain    = $Domain;

    my @nodes = MKDoc::XML::TreeBuilder->process_data ($data);
    for (@nodes) { $class->_process ($_) }
    return MKDoc::XML::TreePrinter->process (@nodes);
}


sub _process
{
    my $class = shift;
    my $tree  = shift;
    return unless (ref $tree);

    local $Prefix = $Prefix;
    local $Domain = $Domain;

    # process the I18N namespace
    foreach my $key (keys %{$tree})
    {
        my $value = $tree->{$key};
        if ($value eq $Namespace)
        {
            next unless ($key =~ /^xmlns\:/);
            delete $tree->{$key};
            $Prefix = $key;
            $Prefix =~ s/^xmlns\://;
        }
    }

    # set the current i18n:domain
    $Domain = delete $tree->{"$Prefix:domain"} || $Domain;

    my $tag  = $tree->{_tag};
    my $attr = { map { /^_/ ? () : ( $_ => $tree->{$_} ) } keys %{$tree} };
    return if ($tag eq '~comment' or $tag eq '~pi' or $tag eq '~declaration');

    # replace attributes with their respective translations 
    $tree->{"$Prefix:attributes"} && do {
        my $attributes = $tree->{"$Prefix:attributes"};
        $attributes =~ s/\s*;\s*$//;
        $attributes =~ s/^\s*//;
        my @attributes = split /\s+\;\s+/, $attributes;
        foreach my $attribute (@attributes)
        {
            # if we have i18n:attributes="alt alt_text", then the
            # attribute name is 'alt' and the
            # translate_id is 'alt_text'
            my ($attribute_name, $translate_id);
            if ($attribute =~ /\s/)
            {
                ($attribute_name, $translate_id) = split /\s+/, $attribute, 2;
            }

            # otherwise, if we have i18n:attributes="alt", then the
            # attribute name is 'alt' and the
            # translate_id is $tree->{'alt'}
            else
            {
                $attribute_name = $attribute;
                $translate_id = _canonicalize ( $tree->{$attribute_name} );
            }

            # the default value if maketext() fails should be the current
            # value of the attribute
            my $default_value = $tree->{$attribute_name};

            # the value to replace the attribute with should be either the
            # translation, or the default value if maketext() failed. 
            my $value = eval { $Petal::TranslationService->maketext ($translate_id) } || $default_value;

            # if maketext() failed, let's know why.
            $@ && warn $@;

            # set the (hopefully) translated value
            $tree->{$attribute_name} = $value;
        }
    };

    # replace content with its translation
    exists $tree->{"$Prefix:translate"} && do {
        my ($translate_id);

        # if we have $Domain:translate="something",
        # then the translate_id is 'something'
        if (defined $tree->{"$Prefix:translate"} and $tree->{"$Prefix:translate"} ne '')
        {
            $translate_id = $tree->{"$Prefix:translate"};
        }

        # otherwise, the translate_id has to be computed
        # from the contents of this node, so that
        # <div i18n:translate="">Hello, <span i18n:name="user">David</span>, how are you?</div>
        # becomes 'Hello, ${user}, how are you?'
        else
        {
            $translate_id = _canonicalize ( _extract_content_string ($tree) );
        }

        # the default value if maketext() fails should be the current
        # value of the attribute
        my $default_value = _canonicalize ( _extract_content_string ($tree) );

        # the value to replace the content with should be either the
        # translation, or the default value if maketext() failed. 
        my $value = eval { $Petal::TranslationService->maketext ($translate_id) } || $default_value;

        # now, $value is supposed to have the translated string, which looks like
        # 'Bonjour, ${user}, comment allez-vous?'. We need to turn this back into
        # a tree structure.
        my %named_nodes  = _extract_named_nodes ($tree);
        my @tokens       = @{Petal::Hash::String->_tokenize (\$value)};
        my @res = map {
        ($_ =~ /$Petal::Hash::String::TOKEN_RE/gsm) ?
            do {
                s/^\$//;
                s/^\{//;
                s/\}$//;
                $named_nodes{$_};
            } :
            do {
                s/\\(.)/$1/gsm;
                $_;
            };
        } @tokens;

        $tree->{_content} = \@res;
    };

    # I know, I know, the I18N namespace processing is a bit broken...
    # It should suffice for now.
    delete $tree->{"$Prefix:attributes"};
    delete $tree->{"$Prefix:translate"};
    delete $tree->{"$Prefix:name"};

    # Do the same i18n thing with child nodes, recursively.
    # for some reason it always makes me think of roller coasters.
    # Yeeeeeeee!
    defined $tree->{_content} and do {
        for (@{$tree->{_content}}) { $class->_process ($_) }
    };
}


sub _canonicalize
{
    my $string = shift;
    $string =~ s/\s+/ /gsm;
    $string =~ s/^ //;
    $string =~ s/ $//;
    return $string;
}


sub _extract_named_nodes
{
    my $tree  = shift;
    my @nodes = ();
    foreach my $node (@{$tree->{_content}})
    {
        ref $node || next;
        push @nodes, $node;
    }
    
    my %nodes = ();
    my $count = 0;
    foreach my $node (@nodes)
    {
        $count++;
        my $name = $node->{"$Prefix:name"} || $count;
        $nodes{$name} = $node;
    }
    
    return %nodes;
}


sub _extract_content_string
{
    my $tree  = shift;
    my @res   = ();

    my $count = 0;
    foreach my $node (@{$tree->{_content}})
    {
        ref $node or do {
            push @res, $node;
            next;
        };
        
        $count++;
        my $name = $node->{"$Prefix:name"} || $count;
        push @res, '${' . $name . '}';
    }
    
    return join '', @res;
}


1;


__END__


=head1 NAME

Petal::I18N - Attempt at implementing ZPT I18N for Petal 


=head1 SYNOPSIS

in your Perl code:

  use Petal;
  use Petal::TranslationService::h4x0r;

  # we want to internationalize to the h4x0rz 31337 l4nGu4g3z. w00t!
  my $translation_service = Petal::TranslationService::h4x0r->new();
  my $template = new Petal (
      file => 'silly_example.xhtml',
      translation_service => $ts,
  );

  print $template->process ();


in silly_example.xhtml

  <html><body>
    <!-- this is a mad example of romanized japanese, which we
         are going to turn into h4x0rz r0m4n|z3d J4paN33z -->

    <div i18n:translate="">
      Konichiwa, <span i18n:name="name">Buruno</span>-san,
      Kyoo wa o-genki desu ka?
    </div>
  </body></html>


... And you get something like:

  <html><body>
    <!-- this is a mad example of romanized japanese, which we
         are going to turn into h4x0rz r0m4n|z3d J4paN33z -->

    <div>K0N1cH1W4, <span>Buruno</span>-s4N, Ky00 w4 o-geNkI DesU kA?</div>
  </body></html>


=head1 HOW IT WORKS

You simply instanciate any kind of object and pass it when you construct the
Petal object, as described in the synopsis. 

As long as this object has an instance method called maketext ($stuff), it'll
work.

At the moment there are two TranslationService objects shipped with the library:

=over 4

=item Petal::TranslationService::h4x0r (rather useless - but kinda fun)

=item Petal::TranslationService::MOFile (works with .mo files produced by gettext)

=back

So if you want to use a .mo file to translate your template, you just do:

   my $ts = Petal::TranslationService::MOFile->new ("/path/to/file.mo");

   my $t  = Petal->new ( file => '/path/to/template.xml',
                         translation_service => $ts );

   print $t->process (%args);


=head1 MORE INFORMATION

You can find the I18N specification at this address.

  L<http://dev.zope.org/Wikis/DevSite/Projects/ComponentArchitecture/ZPTInternationalizationSupport>

At the moment, L<Petal> supports the following constructs:


=over 4

=item xmlns:i18n="http://xml.zope.org/namespaces/i18n"

=item i18n:translate

=item i18n:domain

=item i18n:name

=item i18n:attribute

=back

It does *NOT* (well, not yet) support i18n:source, i18n:target or i18n:data.


=head1 I18N HOWTO

... coming soon :-)

=cut

