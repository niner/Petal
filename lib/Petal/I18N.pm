# ------------------------------------------------------------------
# Petal::I18N - Independant I18N processing
# ------------------------------------------------------------------
package Petal::I18N;
use MKDoc::XML::TreeBuilder;
use MKDoc::XML::TreePrinter;
use Petal::Hash::String;
use MKDoc::XML::Decode;
use strict;
use warnings;
use Carp;


sub process
{
    my $class = shift;
    my $data  = shift;
    my @nodes = MKDoc::XML::TreeBuilder->process_data ($data);
    for (@nodes) { $class->_process ($_) }
    return MKDoc::XML::TreePrinter->process (@nodes);
}


sub _process
{
    my $class = shift;
    my $tree  = shift;
    return unless (ref $tree);

    my $tag  = $tree->{_tag};
    my $attr = { map { /^_/ ? () : ( $_ => $tree->{$_} ) } keys %{$tree} };
    return if ($tag eq '~comment');
    
    # replace attributes with their respective translations 
    $tree->{"i18n:attributes"} && do {
        my $attributes = $tree->{"i18n:attributes"};
        $attributes = s/\s*;\s*$//;
        $attributes = s/^\s*//;

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
    exists $tree->{"i18n:translate"} && do {
        my ($translate_id);

        # if we have i18n:translate="something",
        # then the translate_id is 'something'
        if (defined $tree->{"i18n:translate"} and $tree->{"i18n:translate"} ne '')
        {
            $translate_id = $tree->{"i18n:translate"};
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
    delete $tree->{"xmlsn:i18n"};
    delete $tree->{"i18n:domain"};
    delete $tree->{"i18n:attributes"};
    delete $tree->{"i18n:translate"};
    delete $tree->{"i18n:name"};

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
        my $name = $node->{"i18n:name"} || $count;
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
        my $name = $node->{"i18n:name"} || $count;
        push @res, '${' . $name . '}';
    }
    
    return join '', @res;
}


1;


__END__
