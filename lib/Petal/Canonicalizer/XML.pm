=head1 NAME

Petal::Canonicalizer::XML - Builds an XML canonical Petal file

=head1 DESCRIPTION

This modules mainly implements the XML::Parser 'Stream' interface.
It receives XML events and builds Petal canonical data, i.e.

  <foo petal:if="bar">Hello</foo>

Might be canonicalized to something like

  <?petal:if name="bar"?>
    <foo>Hello</foo>
  <?petal:end?>

=cut
package Petal::Canonicalizer::XML;
use Petal::Hash::String;
use Petal::XML_Encode_Decode;
use strict;
use warnings;

use vars qw /@Result @NodeStack/;


=head2 $class->process ($parser, $data_ref);

returns undef if $parser object (i.e. a Petal::Parser::XML object)
could not parse the data which $data_ref pointed to.

returns a reference to the canonicalized string otherwise.

=cut
sub process
{
    my $class = shift;
    my $parser = shift;
    my $data_ref = shift;
    $data_ref = (ref $data_ref) ? $data_ref : \$data_ref;
    
    # grab anything that's before the first '<' tag
    my ($header) = $$data_ref =~ /(^.*?)<(?!\?|\!)/sm;
    $$data_ref =~ s/(^.*?)<(?!\?|\!)/\</sm;
    
    # grab the <!...> tags which the parser is going to strip
    # in order to reinclude them afterwards
    my @decls = $$data_ref =~ /(<!.*?>)/gsm;
    
    # take the existing processing instructions out and replace
    # them with temporary xml-friendly handlers
    my $pis = $class->_processing_instructions_out ($data_ref);
    
    local @Result = ();
    local @NodeStack = ();
    
    $parser->process ($class, $data_ref);
    
    $header ||= '';
    my $res = $header . (join '', @Result);
    $class->_processing_instructions_in (\$res, $pis);
    
    return \$res;
}


# _processing_instructions_out ($data_ref);
# -----------------------------------------
#   takes the existing processing instructions (i.e. <? blah ?>)
#   and replace them with temporary xml-friendly handlers (i.e.
#   [-- NBXNBBJBNJNBJVNK --]
#
#   returns the <? blah ?> => [-- NBXNBBJBNJNBJVNK --] mapping
#   as a hashref
#
#   NOTE: This is because processing instructions are special to
#   HTML::Parser, XML::Parser etc. and it's easier to just handle
#   them separately
sub _processing_instructions_out
{
    my $class = shift;
    my $data_ref = shift;
    my %pis = map { $_ => $class->_compute_unique_string ($data_ref) } $$data_ref =~ /(<\?.*?\?>)/gsm;
    
    while (my ($key, $value) = each %pis) {
	$$data_ref =~ s/\Q$key\E/$value/gsm;
    }
    
    return \%pis;
}


# _processing_instructions_in ($data_ref, $pis);
# ----------------------------------------------
#   takes the processing instructions mapping defined in the $pis
#   hashref and restores the processing instructions in the data
#   pointed by $data_ref
sub _processing_instructions_in
{
    my $class = shift;
    my $data_ref = shift;
    my $pis = shift;
    while (my ($key, $value) = each %{$pis}) {
	$$data_ref =~ s/\Q$value\E/$key/gsm;
    }
}


# _compute_unique_string ($data_ref)
# ----------------------------------
#   computes a string which does not exist in $$data_ref
sub _compute_unique_string
{
    my $class = shift;
    my $data_ref = shift;
    my $string = '[--' . (join '', map { chr (ord ('a') + int rand 26) } 1..20) . '--]';
    while (index ($$data_ref, $string) >= 0)
    {
	$string = '[--' . (join '', map { chr (ord ('a') + int rand 26) } 1..20) . '--]';
    }
    return $string;
}


=head2 StartTag

Called for every start tag with a second parameter of the element type.
It will check for special PETAL attributes like petal:if, petal:loop, etc...
and rewrite the start tag into @Result accordingly.

For example

  <foo petal:if="blah">

Is rewritten

  <?petal:if name="blah"?><foo>...

=cut
sub StartTag
{
    my $class = shift;
    push @NodeStack, {};
    return if ($class->_is_inside_content_or_replace());
    
    my $tag = $_;
    ($tag) = $tag =~ /^<\s*((?:\w|:)*)/;
    my $att = { %_ };
    
    $class->_define ($tag, $att);
    $class->_condition ($tag, $att);
    $class->_repeat ($tag, $att);
    $class->_replace ($tag, $att);
    
    my $petal = quotemeta ($Petal::NS);
    
    # if a petal:replace attribute was set, then at this point _is_inside_content_or_replace()
    # should return TRUE and this code should not be executed
    unless ($class->_is_inside_content_or_replace())
    {
	# for every attribute which is not a petal: attribute,
	# we need to convert $variable into <?petal:var name="variable"?>
	foreach my $key (keys %{$att})
	{
	    next if ($key =~ /^$petal:/);
	    my $text = $att->{$key};
	    my $token_re = $Petal::Hash::String::TOKEN_RE;
	    my @vars = $text =~ /$token_re/gsm;
	    my %vars = map { $_ => 1 } @vars;
	    @vars = sort { length ($b) <=> length ($a) } keys %vars;
	    foreach my $var (@vars)
	    {
		my $command = $var;
		$command =~ s/^\$//;
		$command =~ s/^\{//;
		$command =~ s/\}$//;
		$command = Petal::XML_Encode_Decode::encode_backslash_semicolon ($command);
		$command = "<?petal:var name=\"$command\"?>";
		$text =~ s/\Q$var\E/$command/g;
	    }
	    $att->{$key} = $text;
	}
	
	$class->_attributes ($tag, $att);
	
	my @att_str = ();
	foreach my $key (keys %{$att})
	{
	    next if ($key =~ /^$petal:/);
	    my $value = $att->{$key};
	    if ($value =~ /^<\?petal:attr/)
	    {
		push @att_str, $value;
	    }
	    else
	    {
		push @att_str, $key . '=' . "\"$value\"";
	    }
	}
	
	my $att_str = join " ", @att_str;
	push @Result, (defined $att_str and $att_str) ? "<$tag $att_str>" : "<$tag>";
	$class->_content ($tag, $att);
    }
}


=head2 EndTag

Called for every end tag with a second parameter of the element type.
It will check in the @NodeStack to see if this end-tag also needs to close
some 'condition' or 'repeat' statements, i.e.

  </li>

Could be rewritten

  </li><?petal:end?>

If the starting LI used a loop, i.e. <li petal:loop="element list">

=cut
sub EndTag
{
    my $class = shift;
    return if ($class->_is_inside_content_or_replace ( 'endtag' ));
    
    my ($tag) = $_ =~ /^<\/\s*((?:\w|:)*)/;
    my $node = pop (@NodeStack);
    
    push @Result, "</$tag>" unless (defined $node->{replace} and $node->{replace});
    my $repeat = $node->{repeat} || '0';
    my $condition = $node->{condition} || '0';
    push @Result, map { '<?petal:end?>' } 1 .. ($repeat+$condition);
}


=head2 Text

Called just before start or end tags.
Turns all variables such as $foo:bar into <?petal var name=":foo bar"?>

=cut
sub Text
{
    my $class = shift;
    return if ($class->_is_inside_content_or_replace());
    my $text = $_;
    my $token_re = $Petal::Hash::String::TOKEN_RE;
    my @vars = $text =~ /$token_re/gsm;
    my %vars = map { $_ => 1 } @vars;
    @vars = sort { length ($b) <=> length ($a) } keys %vars;
    foreach my $var (@vars)
    {
	my $command = $var;
	$command =~ s/^\$//;
	$command =~ s/^\{//;
	$command =~ s/\}$//;
	$command = Petal::XML_Encode_Decode::encode_backslash_semicolon ($command);
	$command = "<?petal:var name=\"$command\"?>";
	$text =~ s/\Q$var\E/$command/g;
    }
    push @Result, $text;
}


# _is_inside_content_or_replace;
# ------------------------------
#   Returns TRUE if @NodeStack contains a node which has a
#   'content' or a 'replace' attribute set.
sub _is_inside_content_or_replace
{
    my $class  = shift;
    my $endtag = shift;
    my $tmp    = undef;
    $tmp = pop (@NodeStack) if ($endtag);
    for (my $i=@NodeStack - 1; $i >= 0; $i--)
    {
	return 1 if ( defined $NodeStack[$i]->{replace} or
		      defined $NodeStack[$i]->{content} )
    }
    push @NodeStack, $tmp if (defined $tmp);
    return;
}


# _split_expression ($expr);
# --------------------------
#   Splits multiple semicolon separated expressions, which
#   are mainly used for the petal:attributes attribute, i.e.
#   would turn "href document.uri; lang document.lang; xml:lang document.lang"
#   into ("href document.uri", "lang document.lang", "xml:lang document.lang")
sub _split_expression
{
    my $class = shift;
    my $expression = shift;
    my @tokens = map { (defined $_ and $_) ? $_ : () }
                 split /(\s|\r|\n)*(?<!\\)\;(\s|\r|\n)*/ms,
		 $expression;
    
    return map { s/^(\s|\n|\r)+//sm;
		 s/(\s|\n|\r)+$//sm;
		 ($_ eq '') ? () : $_ } @tokens;
}


# _define;
# --------
#   Rewrites <tag petal:define="[name] [expression]"> statements into
#   canonical <?petal:var name=":set [name] [expression]"?>
sub _define
{
    my $class = shift;
    return if ($class->_is_inside_content_or_replace());
    
    my $petal = quotemeta ($Petal::NS);
    my $tag   = shift;
    my $att   = shift;
    my $expr  = delete $att->{"$petal:set"}    ||
                delete $att->{"$petal:def"}    ||
                delete $att->{"$petal:define"} || return;
    
    $expr = Petal::XML_Encode_Decode::encode_backslash_semicolon ($expr);
    push @Result, map { "<?petal:var name=\"set: $_\"?>" } $class->_split_expression ($expr);
    return 1;
}


# _condition;
# -----------
#   Rewrites <tag petal:if="[expression]"> statements into
#   <?petal:if name="[expression]"?><tag>
sub _condition
{
    my $class = shift;
    return if ($class->_is_inside_content_or_replace());

    my $petal = quotemeta ($Petal::NS);
    my $tag   = shift;
    my $att   = shift;
    my $expr  = delete $att->{"$petal:if"}        ||
                delete $att->{"$petal:condition"} || return;
    
    $expr = Petal::XML_Encode_Decode::encode_backslash_semicolon ($expr);
    my @new = map { "<?petal:if name=\"$_\"?>" } $class->_split_expression ($expr);
    push @Result, @new;
    $NodeStack[$#NodeStack]->{condition} = scalar @new;
    return 1;
}


# _repeat;
# --------
#   Rewrites <tag petal:loop="[name] [expression]"> statements into
#   <?petal:loop name="[name] [expression]"?><tag>
sub _repeat
{
    my $class = shift;
    return if ($class->_is_inside_content_or_replace());

    my $petal = quotemeta ($Petal::NS);
    my $tag = shift;
    my $att = shift;
    my $expr = delete $att->{"$petal:for"}     ||
               delete $att->{"$petal:foreach"} ||
               delete $att->{"$petal:loop"}    ||
               delete $att->{"$petal:repeat"}  || return;
    
    my @exprs = $class->_split_expression ($expr);
    my @new = ();
    foreach $expr (@exprs)
    {
	$expr = Petal::XML_Encode_Decode::encode_backslash_semicolon ($expr);
	push @new, "<?petal:for name=\"$expr\"?>"
    }
    push @Result, @new;
    $NodeStack[$#NodeStack]->{repeat} = scalar @new;
    return 1;
}


# _replace;
# ---------
#   Rewrites <tag petal:outer="[expression]"> as <?petal:var name="[expression]"?>
#   All the descendent nodes of 'tag' will be skipped
sub _replace
{
    my $class = shift;
    return if ($class->_is_inside_content_or_replace());
    
    my $petal = quotemeta ($Petal::NS);    
    my $tag = shift;
    my $att = shift;
    my $expr = delete $att->{"$petal:replace"} ||
               delete $att->{"$petal:outer"}   || return;
    
    my @new = map {
	$_ = Petal::XML_Encode_Decode::encode_backslash_semicolon ($_);
	"<?petal:var name=\"$_\"?>";
    } split /(\s|\r|\n)*\;(\s|\r|\n)*/ms, $expr;
    
    push @Result, @new;
    $NodeStack[$#NodeStack]->{replace} = 'true';
    return 1;
}


# _attributes;
# ------------
#   Rewrites <?tag attributes="[name1] [expression]"?>
#   as <tag name1="<?var name="[expression]"?>
sub _attributes
{
    my $class = shift;
    return if ($class->_is_inside_content_or_replace());
    
    my $petal = quotemeta ($Petal::NS);    
    my $tag = shift;
    my $att = shift;
    my $expr = delete $att->{"$petal:att"}        ||
               delete $att->{"$petal:attr"}       ||
               delete $att->{"$petal:atts"}       ||
	       delete $att->{"$petal:attributes"} || return;
    
    foreach my $string ($class->_split_expression ($expr))
    {
	next unless (defined $string);
	next if ($string =~ /^\s*$/);
	my ($attr, $expr) = $string =~ /^\s*((?:\w|\:)+)\s+(.*?)\s*$/;
	$expr = Petal::XML_Encode_Decode::encode_backslash_semicolon ($expr);
	$att->{$attr} = "<?petal:attr name=\"$attr\" value=\"$expr\"?>";
    }
    return 1;
}


# _content;
# ---------
#   Rewrites <tag petal:inner="[expression]"> as <tag><?petal:var name="[expression]"?>
#   All the descendent nodes of 'tag' will be skipped
sub _content
{
    my $class = shift;
    return if ($class->_is_inside_content_or_replace());
    
    my $petal = quotemeta ($Petal::NS);    
    my $tag = shift;
    my $att = shift;
    my $expr = delete $att->{"$petal:content"}  ||
               delete $att->{"$petal:contents"} ||
	       delete $att->{"$petal:inner"}    || return;
    my @new = map {
	$_ = Petal::XML_Encode_Decode::encode_backslash_semicolon ($_);
	"<?petal:var name=\"$_\"?>";
    } $class->_split_expression ($expr);
    push @Result, @new;
    $NodeStack[$#NodeStack]->{content} = 'true';
    return 1;
}


=head1 AUTHOR

Jean-Michel Hiver <jhiver@mkdoc.com>

This module is redistributed under the same license as Perl itself. 

=cut


1;


__END__
