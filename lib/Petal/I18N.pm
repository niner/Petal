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
    
    # replace attributes with translated ones
    $tree->{"i18n:attributes"} && do {
        my $attributes = $tree->{"i18n:attributes"};
        $attributes = s/\s*;\s*$//;
        $attributes = s/^\s*//;

        my @attributes = split /\s+\;\s+/, $attributes;
        foreach my $attribute (@attributes)
        {
            my ($attribute_name, $attribute_translate_id, $attribute_value);

            if ($attribute =~ /\s/)
            {
                ($attribute_name, $attribute_translate_id) = split /\s+/, $attribute, 2;
                $attribute_value = $tree->{$attribute_name};
                $attribute_value = $Petal::TranslationService->get_from_id     ( $attribute_translate_id ) ||
                                   $Petal::TranslationService->get_from_string ( $attribute_value        ) ||
                                   $attribute_value;
            }
            else
            {
                $attribute_name  = $attribute;
                $attribute_value = $tree->{$attribute_name};
                $attribute_value = $Petal::TranslationService->get_from_string ( $attribute_value        ) ||
                                   $attribute_value;
            }

            $tree->{$attribute_name} = $attribute_value;
        }
    };

    # replace content with translated content
    $tree->{"i18n:translate"} && do {
        my $translate_id  = $tree->{"i18n:translate"};
        my $content_value = _extract_content_string ($tree);
        $content_value = $Petal::TranslationService->get_from_id     ( $translate_id  ) ||
                         $Petal::TranslationService->get_from_string ( $content_value ) ||
                         $content_value;

        my %named_nodes  = _extract_named_nodes ($tree);
        my @tokens       = @{Petal::Hash::String->_tokenize (\$content_value)};
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

    # I know, I know, the I18N stuff isn't strip all i18n stuff
    delete $tree->{"xmlsn:i18n"};
    delete $tree->{"i18n:attributes"};
    delete $tree->{"i18n:translate"};
    delete $tree->{"i18n:name"};

    # do the same thing with child nodes
    defined $tree->{_content} and do {
        for (@{$tree->{_content}}) { $class->_process ($_) }
    };
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
        push @res, '$' . $name;
    }
    
    return join '', @res;
}


1;


__END__
