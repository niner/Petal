# ------------------------------------------------------------------
# Petal::CodeGenerator - Generates Perl code from canonical syntax
# ------------------------------------------------------------------
# Author: Jean-Michel Hiver
# Description: This class parses a template in 'canonical syntax'
# (referred as the 'UGLY SYNTAX' in the manual) and generates Perl
# code that can be turned into a subroutine using eval().
# ------------------------------------------------------------------
package Petal::CodeGenerator;
use Petal::XML_Encode_Decode;
use strict;
use warnings;
use Carp;

our $PI_RE = '^<\?(?:\s|\r|\n)*(attr|include|var|if|condition|else|repeat|loop|foreach|for|eval|endeval|end).*?\?>$';
use vars qw /$petal_object $tokens $variables @code $indent $token_name %token_hash $token $my_array/;


# these _xxx_res primitives have been contributed by Fergal Daly <fergal@esatclear.ie>
# they speed up string construction a little bit
sub _init_res
{
	return '$res = ""';
}


sub _add_res
{
	my $class = shift;

	my $thing = shift;

	return qq{\$res .= $thing};
}


sub _final_res
{
	return q{$res};
}


sub _get_res
{
	return q{$res};
}


# $class->process ($data_ref, $petal_object);
# -------------------------------------------
# This (too big) subroutine converts the canonicalized template
# data into Perl code which is ready to be evaled and executed.
sub process
{
    my $class = shift;
    my $data_ref = shift;
    
    local $petal_object = shift || die "$class::" . "process: \$petal_object was not defined";
    
    local $tokens = $class->_tokenize ($data_ref);
    local $variables = {};
    local @code = ();
    local $indent = 0;
    local $token_name = undef;
    local %token_hash = ();
    local $token = undef;
    local $my_array = {};
    
    push @code, "    " x $indent . "\$VAR1 = sub {";
    $indent++;
    push @code, "    " x $indent . "my \$hash = shift;";
    push @code, "    " x $indent . "my ".$class->_init_res.";";
    
    foreach $token (@{$tokens})
    {
        if ($token =~ /$PI_RE/)
        {
	    ($token_name) = $token =~ /$PI_RE/;
	    my @atts1 = $token =~ /(\S+)\=\"(.*?)\"/gos;
	    my @atts2 = $token =~ /(\S+)\=\'(.*?)\'/gos;
	    %token_hash = (@atts1, @atts2); 
	    foreach my $key (%token_hash)
	    {
		$token_hash{$key} = Petal::XML_Encode_Decode::decode_backslash_semicolon ($token_hash{$key})
		    if (defined $token_hash{$key});
	    }
	    
          CASE:
            for ($token_name)
	    {
                /^attr$/      and do { $class->_attr;    last CASE };
                /^include$/   and do { $class->_include; last CASE };
		/^var$/       and do { $class->_var;     last CASE };
		/^if$/        and do { $class->_if;      last CASE };
		/^condition$/ and do { $class->_if;      last CASE };
                /^else$/      and do { $class->_else;    last CASE };
		/^repeat$/    and do { $class->_for;     last CASE };
		/^loop$/      and do { $class->_for;     last CASE };
		/^foreach$/   and do { $class->_for;     last CASE };
		/^for$/       and do { $class->_for;     last CASE };
		/^eval$/      and do { $class->_eval;    last CASE };
		/^endeval$/   and do { $class->_endeval; last CASE };
		
		/^end$/ and do
                {
		    delete $my_array->{$indent};
                    $indent--;
		    
                    push @code, ("    " x $indent . "}");
                    last CASE;
                };
	    }
	}
	else
	{
            my $string = $token;
            $string =~ s/\@/\\\@/gsm;
            $string =~ s/\$/\\\$/gsm;
            $string =~ s/\n/\\n/gsm;
            $string =~ s/\n//gsm;
            $string =~ s/\"/\\\"/gsm;
            push @code, ("    " x $indent . $class->_add_res( '"' . $string . '";'));
        }
    }
    
    push @code, "    " x $indent . "return ". $class->_final_res() .";";
    $indent--;
    push @code, "    " x $indent . "};";
    
    return join "\n", @code;
}


# $class->_include;
# -----------------
# process a <?include file="/foo/blah.html"?> file
sub _include
{
    my $class = shift;
    my $file  = $token_hash{file};
    my $path  = $petal_object->_include_compute_path ($file);
    my $lang  = $petal_object->language();
    if (defined $lang and $lang)
    {
        push @code, ("    " x $indent . $class->_add_res("Petal->new (file => '$path', lang => '$lang')->process (\$hash->new());"));
    }
    else
    {
        push @code, ("    " x $indent . $class->_add_res("Petal->new ('$path')->process (\$hash->new());"));
    }
}


# $class->_var;
# -------------
# process a <?var name="blah"?> statement
sub _var
{
    my $class = shift;
    my $variable = $token_hash{name} or
        confess "Cannot parse $token : 'name' attribute is not defined";
    
    (defined $variable and $variable) or
        confess "Cannot parse $token : 'name' attribute is not defined";

    # set the variable in the $variables hash
    my $tmp = $variable;
    $tmp =~ s/\..*//;
    $variables->{$tmp} = 1;
    
    $variable =~ s/\'/\\\'/g;
    push @code, ("    " x $indent . $class->_add_res("\$hash->get ('$variable');"));
}


# $class->_if;
# ------------
# process a <?if name="blah"?> statement
sub _if
{
    my $class = shift;
    my $variable = $token_hash{name} or
        confess "Cannot parse $token : 'name' attribute is not defined";
    
    (defined $variable and $variable) or
        confess "Cannot parse $token : 'name' attribute is not defined";
		    
    # set the variable in the $variables hash
    my $tmp = $variable;
    $tmp =~ s/\..*//;
    $variables->{$tmp} = 1;
    
    $variable =~ s/\'/\\\'/g;
    push @code, ("    " x $indent . "if (\$hash->get ('$variable')) {");
    $indent++;
}


# $class->_eval;
# -------------------
# process a <?eval?> statement
sub _eval
{
    my $class = shift;
    push @code, ("    " x $indent . $class->_add_res("eval {"));    
    $indent++;
    push @code, ("    " x $indent . "my " . $class->_init_res() .";");
    push @code, ("    " x $indent . "local %SIG;");
    push @code, ("    " x $indent . "\$SIG{__DIE__} = sub { \$\@ = shift };");
}


# $class->_endeval;
# -----------------
# process a <?endeval errormsg="..."?> statement
sub _endeval
{   
    my $class = shift;
    my $variable = $token_hash{'errormsg'} or
       confess "Cannot parse $token : 'errormsg' attribute is not defined";
    
    push @code, ("    " x $indent . "return " . $class->_get_res() . ";");
    $indent--;
    push @code, ("    " x $indent . "};");

    push @code, ("    " x $indent . "if (defined \$\@ and \$\@) {");
    $indent++;
    $variable = quotemeta ($variable);
    push @code, ("    " x $indent . $class->_add_res("\"$variable\";"));
    $indent--;
    push @code, ("    " x $indent . "}");
}


# $class->_attr;
# --------------
# process a <?attr name="blah"?> statement
sub _attr
{
    my $class = shift;
    my $attribute = $token_hash{name} or
        confess "Cannot parse $token : 'name' attribute is not defined";

    my $variable = $token_hash{value} or
        confess "Cannot parse $token : 'value' attribute is not defined";
    
    (defined $variable and $variable) or
        confess "Cannot parse $token : 'value' attribute is not defined";
    
    # set the variable in the $variables hash
    my $tmp = $variable;
    $tmp =~ s/\..*//;
    $variables->{$tmp} = 1;
    
    $variable =~ s/\'/\\\'/g;
    push @code, ("    " x $indent . "if (defined \$hash->get ('$variable') and \$hash->get ('$variable') ne '') {");
    push @code, ("    " x ++$indent . $class->_add_res("\"$attribute\" . '=\"' . \$hash->get ('$variable') . '\"'"));
    push @code, ("    " x --$indent . "}");
}


# $class->_else;
# --------------
# process a <?else name="blah"?> statement
sub _else
{
    my $class = shift;
    $indent--;
    push @code, ("    " x $indent . "}");
    push @code, ("    " x $indent . "else {");
    $indent++;
}


# $class->_for;
# -------------
# process a <?for name="some_list" as="element"?> statement
sub _for
{
    my $class = shift;
    my $variable = $token_hash{name} or
    confess "Cannot parse $token : 'name' attribute is not defined";
    
    (defined $variable and $variable) or
    confess "Cannot parse $token : 'name' attribute is not defined";
    
    $variable =~ s/^\s+//;
    my $as;
    ($as, $variable) = split /\s+/, $variable, 2;
    
    (defined $as and defined $variable) or
        confess "Cannot parse $token : loop name not specified";
    
    # set the variable in the $variables hash
    my $tmp = $variable;
    $tmp =~ s/\..*//;
    $variables->{$tmp} = 1;
    
    $variable =~ s/\'/\\\'/g;
    unless (defined $my_array->{$indent})
    {
	push @code, ("    " x $indent . "my \@array = \@{\$hash->get ('$variable')};");
	$my_array->{$indent} = 1;
    }
    else
    {
	push @code, ("    " x $indent . "\@array = \@{\$hash->get ('$variable')};");
    }
    
    push @code, ("    " x $indent . "for (my \$i=0; \$i < \@array; \$i++) {");
    $indent++;
    push @code, ("    " x $indent . "my \$hash = \$hash->new();");
    push @code, ("    " x $indent . "my \$count= \$i + 1;");
    push @code, ("    " x $indent . "\$hash->{__count__}    = \$count;");
    push @code, ("    " x $indent . "\$hash->{__is_first__} = (\$count == 1);");
    push @code, ("    " x $indent . "\$hash->{__is_last__}  = (\$count == \@array);");
    push @code, ("    " x $indent . "\$hash->{__is_inner__} = " .
		                        "(not \$hash->{__is_first__} " . 
		                        "and not \$hash->{__is_last__});");
    
    push @code, ("    " x $indent . "\$hash->{__even__}     = (\$count % 2 == 0);");
    push @code, ("    " x $indent . "\$hash->{__odd__}      = not \$hash->{__even__};");
    push @code, ("    " x $indent . "\$hash->{'$as'} = \$array[\$i];");
}


# $class->_tokenize ($data_ref);
# ------------------------------
# Returns the data to process as a list of tokens:
# ( 'some text', '<% a_tag %>', 'some more text', '<% end-a_tag %>' etc.
sub _tokenize
{
    my $self = shift;
    my $data_ref = shift;
    
    my @tags  = $$data_ref =~ /(<\?.*?\?>)/gs;
    my @split = split /(?:<\?.*?\?>)/s, $$data_ref;
    
    my $tokens = [];
    while (@split)
    {
        push @{$tokens}, shift (@split);
        push @{$tokens}, shift (@tags) if (@tags);
    }
    push @{$tokens}, (@tags);
    return $tokens;
}


1;
