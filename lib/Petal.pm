=head1 NAME

Petal - Perl Template Attribute Language

=head1 SYNOPSIS

  use Petal;
  @Petal::BASE_DIR = qw |. ./templates /var/www/templates|;
  my $template = new Petal ( 'test.xml' );
  print $template->process (
    some_hash   => $hashref,
    some_array  => $arrayref,
    some_object => $object,
  );

Join the Petal mailing list:

  http://lists.webarch.co.uk/mailman/listinfo/petal

=head1 SUMMARY

Petal is a XML based templating engine that is able to process any
kind of XML. HTML parsing and XHTML is also supported.

Because Petal borrows a lot of good ideas from the Zope Page Templates
TAL specification, it is very well suited for the creation of truly WYSIWYG
XHTML editable templates.

The idea is to enforce even further the separation of logic and
presentation. With Petal, graphic designers who use their favorite
WYSIWYG editor can easily edit templates without having to worry about
the loops and ifs which happen behind the scenes.

Besides, you can safely send the result of their work through HTML tidy
to make sure that you always output neat, standard compliant, valid XML
pages.

=cut
package Petal;
use Petal::Hash;
use Petal::CodeGenerator;
use Petal::Cache::Disk;
use Petal::Cache::Memory;
use Petal::Parser::XMLWrapper;
use Petal::Parser::HTMLWrapper;
use Petal::Canonicalizer::XML;
use Petal::Canonicalizer::XHTML;
use strict;
use warnings;
use Carp;
use Safe;
use File::Spec;

# these are used as local variables when the XML::Parser
# is crunching templates...
use vars qw /@tokens @nodeStack/;


=head1 GLOBAL VARIABLES

=head2 Description

$INPUT - Currently acceptable values are

  'XML'   - Petal will use XML::Parser to parse the template
  'HTML'  - Petal will use HTML::TreeBuilder to parse the template
  'XHTML' - Alias for 'HTML'

This variable defaults to 'XML'.

=cut
our $INPUT  = 'XML';
our $INPUTS = {
    'XML'   => 'Petal::Parser::XMLWrapper',
    'HTML'  => 'Petal::Parser::HTMLWrapper',
    'XHTML' => 'Petal::Parser::HTMLWrapper',
};


=pod

$OUTPUT - Currently acceptable values are

  'XML'   - Petal will output generic XML
  'XHTML' - Same as XML except for tags like <br /> or <input />

=cut
our $OUTPUT  = 'XML';
our $OUTPUTS = {
    'XML'   => 'Petal::Canonicalizer::XML',
    'HTML'  => 'Petal::Canonicalizer::XHTML',
    'XHTML' => 'Petal::Canonicalizer::XHTML',
};


=pod

$TAINT - If set to TRUE, makes perl taint mode happy. Defaults to FALSE.

=cut
our $TAINT = undef;


=pod

@BASE_DIR - Base directories from which the templates should be retrieved.
Petal will try to fetch the template file starting from the beginning of the
list until it finds one base directory which has the requested file.

@BASE_DIR defaults to ('.', '/').

=cut
our @BASE_DIR = ('.', '/');
our $BASE_DIR = undef; # for backwards compatibility...

=pod

$DISK_CACHE  - If set to FALSE, Petal will not use the Petal::Disk::Cache module. Defaults to TRUE.

=cut
our $DISK_CACHE = 1;


=pod

$MEMORY_CACHE - If set to FALSE, Petal will not use the Petal::Disk::Memory module. Defaults to TRUE.

=cut
our $MEMORY_CACHE = 1;


our $VERSION = '0.7';


=head2 Example

  # at the beginning of your program:

  # try to look up for file in '.', then in '..', then...
  @Petal::BASE_DIR = ('.', '..', '~/default/templates');

  # vroom!
  $Petal::DISK_CACHE = 1;
  $Petal::MEMORY_CACHE = 1;

  # we are parsing a valid XHTML file, and we want to output
  # XHTML as well...
  $Petal::INPUT = 'XML';
  $Petal::OUTPUT = 'XHTML';  

=cut


=head1 METHODS

=head2 $class->new ( file => $file );

Instanciates a new Petal object.

=cut
sub new
{
    my $class = shift;
    $class = ref $class || $class;
    unshift (@_, 'file') if (@_ == 1);
    return bless { @_ }, $class;
}


=head2 $self->process (%hash);

Processes the current template object with the information contained in
%hash. This information can be scalars, hash references, array
references or objects.

Example:

  my $data_out = $template->process (
    user   => $user,
    page   => $page,
    basket => $shopping_basket,    
  );

  print "Content-Type: text/html\n\n";
  print $data_out;

=cut
sub process
{
    my $self = shift;
   
    # make the hash highly magical
    my $hash = (@_ == 1 and ref $_[0] eq 'HASH') ?
        new Petal::Hash (%{$_[0]}) :
        new Petal::Hash (@_);
    
    my $coderef = $self->_code_memory_cached;
    my $res = undef;
    eval { $res = $coderef->($hash) };
    if (defined $@ and $@) { confess $@ . "\n===\n\n" . $self->_code_with_line_numbers }
    return $res;
}


# $self->code_with_line_numbers;
# ------------------------------
#   utility method to return the Perl code, each line being prefixed with
#   its number... handy for debugging templates. The nifty line number padding
#   patch was provided by Lucas Saud <lucas.marinho@uol.com.br>.
sub _code_with_line_numbers
{
    my $self = shift;
    my $code = $self->_code_disk_cached;

    # get lines of code
    my @lines = split(/\n/, $code);

    # add line numbers
    my $count = 0;
    @lines = map {
      my $cur_line = $_;
      $count++;

      # space padding so the line numbers nicely line up with each other
      my $line_num = sprintf("%" . length(scalar(@lines)) . "d", $count);

      # put line number and line back together
      "${line_num} ${cur_line}";
    } @lines;

    return join("\n", @lines);
}


# $self->_file;
# -------------
#   setter / getter for the 'file' attribute
sub _file
{
    my $self = shift;
    $self->{file} = shift if (@_);
    $self->{file} =~ s/^\///;
    return $self->{file};
}


# $self->_file_path;
# ------------------
#   computes the file of the absolute path where the template
#   file should be fetched
sub _file_path
{
    my $self = shift;
    my $file = $self->_file;
    if (defined $BASE_DIR)
    {
	my $base_dir = File::Spec->canonpath ($BASE_DIR);
	$base_dir = File::Spec->rel2abs ($base_dir) unless ($base_dir =~ /^\//);
	$base_dir =~ s/\/$//;
	my $file_path = File::Spec->canonpath ($base_dir . '/' . $file);
	return $file_path if (-e $file_path and -r $file_path);
    }
    
    foreach my $dir (@BASE_DIR)
    {
	my $base_dir = File::Spec->canonpath ($dir);
	$base_dir = File::Spec->rel2abs ($base_dir) unless ($base_dir =~ /^\//);
	$base_dir =~ s/\/$//;
	my $file_path = File::Spec->canonpath ($base_dir . '/' . $file);
	return $file_path if (-e $file_path and -r $file_path);
    }
    
    confess ("Cannot find $file in @BASE_DIR. (typo? permission problem?)");
}


# $self->_file_data_ref;
# ----------------------
#   slurps the template data into a variable and returns a
#   reference to that variable
sub _file_data_ref
{
    my $self = shift;
    my $file_path = $self->_file_path;
    open FP, "<$file_path" or
        confess "Cannot read-open $file_path";
    my $data = join '', <FP>;
    close FP;

    # kill template comments
    $data =~ s/\<!--\?.*?\-->//gsm;
    
    # if there are any <?petal:xxx ... > instead of
    # <?petal:xxx ... ?>, issuing a warning would be _good_
    my @decl =  $data =~ /(\<\?petal\:.*?>)/gsm;
    for (@decl)
    {
	next if /\?\>$/;
	croak "Bad petal statement: $_ (missing question mark)";
    }
    return \$data;
}


# $self->_code_disk_cached;
# -------------------------
#   Returns the Perl code data, using the disk cache if
#   possible
sub _code_disk_cached
{
    my $self = shift;
    my $file = $self->_file_path;
    my $code = (defined $DISK_CACHE and $DISK_CACHE) ? Petal::Cache::Disk->get ($file) : undef;
    unless (defined $code)
    {
	my $data_ref = $self->_file_data_ref;
	$data_ref  = $self->_canonicalize;
	$code = Petal::CodeGenerator->process ($data_ref, $self);
	Petal::Cache::Disk->set ($file, $code) if (defined $DISK_CACHE and $DISK_CACHE);
    }
    return $code;
}


# $self->_code_memory_cached;
# ---------------------------
#   Returns the Perl code data, using the disk cache if
#   possible
sub _code_memory_cached
{
    my $self = shift;
    my $file = $self->_file_path;
    my $code = (defined $MEMORY_CACHE and $MEMORY_CACHE) ? Petal::Cache::Memory->get ($file) : undef;
    unless (defined $code)
    {
	my $code_perl = $self->_code_disk_cached;
        my $VAR1 = undef;
	
	if ($TAINT)
	{
	    # important line, don't remove
	    ($code_perl) = $code_perl =~ m/^(.+)$/s;
	    my $cpt = Safe->new ("Petal::CPT");
	    $cpt->reval($code_perl);
	    die $@ if ($@);
	    
	    # remove silly warning '"Petal::CPT::VAR1" used only once'
	    $Petal::CPT::VAR1 if (0);
	    $code = $Petal::CPT::VAR1;
	}
	else
	{
	    eval "$code_perl";
	    confess $@ if (defined $@ and $@);
	    $code = $VAR1;
	}
	
        Petal::Cache::Memory->set ($file, $code) if (defined $MEMORY_CACHE and $MEMORY_CACHE);
    }
    return $code;
}


# $self->_code_cache;
# -------------------
#   Returns TRUE if this object uses the code cache, FALSE otherwise
sub _memory_cache
{
    my $self = shift;
    return $self->{memory_cache} if (defined $self->{memory_cache});
    return $MEMORY_CACHE;
}


# $self->_canonicalize;
# ---------------------
#   Returns the canonical data which will be sent to the
#   Petal::CodeGenerator module
sub _canonicalize
{
    my $self = shift;
    my $parser_type        = $INPUTS->{$INPUT}   || confess "unknown \$Petal::INPUT = $INPUT";
    my $canonicalizer_type = $OUTPUTS->{$OUTPUT} || confess "unknown \$Petal::OUTPUT = $OUTPUT";
    
    my $data_ref = $self->_file_data_ref;
    my $parser = $parser_type->new;
    return $canonicalizer_type->process ($parser, $data_ref);
}


1;


__END__

=head1 Overview

Currently, Petal supports three different syntaxes:

* A 'Canonical' Syntax

  This is my variable: <?petal:var name="my_variable"?>

* A 'TAL-like' Syntax

  This is my variable: <span petal:replace="my_variable">Dummy Variable</span>

* An 'Inline' Syntax

  This is my variable: $my_variable

You can use all three syntaxes in the same template file. In order to ease
maintenance, Petal internally re-writes your templates into the canonical
syntax.

The cycle of a Petal template is the following:

  1. Read the source XML template
  2. $INPUT (XML or HTML) throws XML events from the source file
  3. $OUTPUT (XML or HTML) uses these XML events to canonicalize the template
  4. Petal::CodeGenerator turns the canonical template into Perl code
  5. Petal::Cache::Disk caches the Perl code on disk
  6. Petal turns the perl code into a subroutine
  7. Petal::Cache::Memory caches the subroutine in memory
  8. Petal executes the subroutine

If you are under a persistent environement a la mod_perl, subsequent calls
to the same template will be reduced to step 8 until the source template
changes.

Otherwise, subsequent calls will resume at step 6, until the source template
changes.


=head1 Petal Syntax Summary

Petal features a flexible, XML-compliant syntax which can be summarized
as follows:

=head2 Template comments

  <!--? This will not be in the output ?-->


=head2 "Simple" syntax (Variable Interpolation)

  $my_variable
  $my_object/my_method
  $my_array/2
  $my_hash/some_key


=head2 "TAL-like" syntax, i.e.

  <li petal:repeat="element list"
      petal:content="element">Some dummy element</li>

Which if 'list' was ('foo', 'bar', 'baz') would output:

  <li>foo</li>
  <li>bar</li>
  <li>baz</li>


=head2 "Usual" syntax (like HTML::Template, Template::Toolkit, etc), i.e

  <?petal:condition name="list"?>
    <?petal:repeat name="element list"?>
      <li><?petal:var name="element"?></li>
    <?end?>
  <?end?>


=head1 Variable expressions and modifiers

Petal has the ability to bind template variables to the following Perl
datatypes: scalars, lists, hash, arrays and object.


=head2 How it works

  <?petal:var name="user/login"?>

Is *EXACTLY* the same as writing

  <?petal:var name="var:user/login"?>

Which internally is turned into

  push @out, $hash->{'var:user/login'};

$hash is an highly magical hash which is tied to the Petal::Hash class,
and uses the 'var:' information to pass the expression 'user/login' to
the Petal::Hash::VAR module.

The Petal::Hash::VAR module has access to $hash, and has the
responsibility to resolve the user/login expression. So if
$hash->{'user'} is an object and 'login' is a method on this object,
'user/login' will do the 'Right Thing' and return
$hash->{user}->login();


=head2 Expression evaluation

Using a uniform, simple syntax you can access:

  * scalars: <?petal:var name="my_scalar"?>
  * hashes: <?petal:var name="my_hash/key"?>
  * arrays: <?petal:var name="my_array/12"?>
  * objects methods: <?petal:var name="my_object/my_method" ?>

Note that you can also pass arguments to object methods.  Let's say that
you have an object 'math', you could do:

  2+2 = <?petal:var name="math/add '2' '2'"?>

Even more powerful, let's say that you have:

  $hash = { math => $math_object, number => 3 }

You could write the following:

  $number+$number = <?petal:var name="math/add number number"?>

Which would output:

  3+3 = 6

If you wonder how it all works, I suggest that you take a look at the
Petal::Hash and Petal::Hash::VAR modules.


=head2 Expression modifiers

We have seen that var: maps to Petal::Hash::VAR, which evaluates
expressions.

There are other modifiers, which map to the following modules:

  xml:         => Petal::Hash::Encode_XML
  encode:      => (alias for :xml)
  encode_html: => Petal::Hash::Encode_HTML
  true:        => Petal::Hash::TRUE
  false:       => Petal::Hash::FALSE
  not:         => (alias for :false)
  set:         => Petal::Hash::SET

You can write your own modifiers easily by just subclassing
Petal::Hash::VAR.  Look at the Petal::Hash POD for more information on
how to do this.


=head3 xml: / encode:

These will let you output a variable, but encodes the XML entities.  Let
us say that:

  $user/name

Produces:

  Smith & Co.

Which is invalid XML. You could write:

  $encode:user/name

Or

  <?petal:var name="encode: user/name"?>

Or

  <span petal:replace="encode: user/name">User Name Here</span>


=head3 true:

Mainly to be used with expressions such as

  <?petal:if name="true: user/has_access"?>


=head3 false:

I'm pretty sure you can work it out by yourself:-)


=head3 set:

This one is the wierdest modifier. It will return __NOTHING__ no matter
what, but will set the result into the hash. For instance:

  <?petal:var name="foo/bar"?>

Could be rewritten:

  <?petal:var name="set: newVariableNameForBar foo/bar"?>
  <?petal:var name="newVariableNameForBar"?>

This is mainly intended so that if you have a.very.very.long.expression,
you can alias it to something like 'vLongExpr' and save some typing (as
well as providing a slight performance boost if you're using the
expression inside a loop).


=head1 Petal TAL-like syntax

This functionality is inspired from TAL, the specification of which is
there: http://www.zope.org/Wikis/DevSite/Projects/ZPT/TAL. In order to
save some typing I'll just point out the differences and important
points:

* The prefix is not tal:, but petal:. It's two extra characters to write but
  although Petal is partly inspired from TAL, it does _NOT_ implement the TAL
  specification which justifies the fact that a different namespace is used.


=head2 define

  <!-- sets document/title to 'title' -->
  <span petal:define="title document/title">


=head2 condition (ifs)

  <span petal:condition="user/is_authenticated">
    Yo, authenticated!
  </span>


=head2 repeat (loops)

  <li petal:repeat="user system/user_list">$xml:user/real_name</li>


=head2 attributes

  <a href="http://www.gianthard.com"
     lang="en-gb"
     petal:attributes="href document/href_relative; lang document/lang">


=head2 interpolation

  <span petal:content="xml:title">Dummy Title</span>
  <span petal:replace="xml:title">Dummy Title</span>

'petal:content' and 'petal:replace' are *NOT* aliases. The former will
replace the contents of the span tag, while the latter will replace the
whole span tag.


=head2 Composite constructs

You can do things like:

  <p petal:define="children document/children"
     petal:condition="children"
     petal:repeat="child children"
     petal:attributes="lang child/lang; xml:lang child/lang"
     petal:content="child/data">Some Dummy Content</p>

Given the fact that XML attributes are not ordered, withing the same tag
statements will be executed in the following order: define, condition,
repeat, (attributes, content) or (replace).


=head2 Aliases

On top of all that, for people who are lazy at typing the following
aliases are provided (although I would recommend sticking to the
defaults):

  * petal:define     - petal:def, petal:set
  * petal:condition  - petal:if
  * petal:repeat     - petal:for, petal:loop, petal:foreach
  * petal:attributes - petal:att, petal:attr, petal:atts
  * petal:content    - petal:inner
  * petal:replace    - petal:outer


=head2 Simple Variable Interpolation

It's the simplest way to insert values in the template:

  Hello, $user/login
  Your real name is $xml:user/real_name!

If $user is a hash reference, then the engine will fetch the value
matching the 'login' key. If it's an object, it will try to see if there
is a $user->login method, otherwise it will try to fetch $user->{login}. 

The xml:user/real_name tells the template engine to XML encode the
fetched value, i.e. 'John Smith & Son' will be converted to 'John Smith
&amp; Son'.

Alternatively, you could have used $encode:user/real_name to get the
same behavior. This is it, you cannot do anything more complex than
variable interpolation with that syntax.


=head1 XML Declaration Syntax

=head2 Variables and Modifiers

  <?petal:var name="document/title"?>

=head3 If / Else constructs

Usual stuff:

  <?petal:if name="user/is_birthay"?>
    Happy Birthday, $xml:user/real_name!
  <?petal:else?>
    What?! It's not your birthday?
    A very merry unbirthday to you! 
  <?petal:end?>

You can use petal:condition instead of petal:if, and indeed you can use
modifiers:

  <?petal:condition name="false: user/is_birthay"?>
    What?! It's not your birthday?
    A very merry unbirthday to you! 
  <?petal:else?>
    Happy Birthday, $xml:user/real_name!
  <?petal:end?>

Not much else to say!


=head3 Loops

Use either petal:for, petal:foreach, petal:loop or petal:repeat. They're
all the same thing, which one you use is a matter of taste. Again no
surprise:

  <h1>Listing of user logins</h1>
  <ul>
    <?petal:repeat name="user system/list_users"?>
      <li>$user/login : $user/real_name</li>
    <?petal:end?>
  </ul>
  

Variables are scoped inside loops so you don't risk to erase an existing
'user' variable which would be outside the loop. The template engine
also provides the following variables for you inside the loop:

  <?petal:repeat name="foo bar"?>
    $__count__    - iteration number, starting at 1
    $__is_first__ - is it the first iteration
    $__is_last__  - is it the last iteration
    $__is_inner__ - is it not the first and not the last iteration
    $__even__     - is the count even
    $__odd__      - is the count odd
  <?petal:end?>

Again these variables are scoped, you can safely nest loops, ifs etc...
as much as you like and everything should be fine. And if it's not,
it's a bug :-)


=head1 Includes

Petal fully support includes using the following syntax:

  <?petal:include file="include.xml"?>

And it will include the file 'include.xml', using the current object
base_dir attribute. Petal includes occur at RUN TIME. That means that
there is NO SUPPORT to prevent infinite includes, which is usually not
so much of a deal since it happens at run time...

This should let you build templates which have a recursive behavior
which can be useful to apply templates to any tree-shaped structure (i.e.
sitemaps, threads, etc).

If you want use XML::Parser to include files, you should make sure that
the included files are valid XML themselves... FYI XML::Parser chokes on this:

<p>foo</p>
<p>bar</p>

But this works:

<div>
  <p>foo</p>
  <p>bar</p>
</div>

(having only one top element is part of the XML spec).


=head1 EXPORT

None.


=head1 BUGS

The XML::Parser wrapper cannot expand any other entity than &lt;, &gt; &amp;
and &quot;.

Both XML::Parser and HTML::TreeBuilder expand all entities, hence &nbsp;s are
lost.

XML::Parser is deprecated and should be replaced by SAX handlers at some point.

Problems have been reported with the petal cache on a (Apache + Windows +
mod_perl) platform.


=head1 AUTHOR

Copyright 2002 - Jean-Michel Hiver <jhiver@mkdoc.com> 

This module free software and is distributed under the
same license as Perl itself.

Many thanks to:

William McKee <william@knowmad.com> for his useful suggestions,
patches, and bug reports.

Sean M. Burke <sburke@cpan.org> for his improvements on the
HTML::TreeBuilder module which tremendously helped with HTML
parsing.

Lucas Saud <lucas.marinho@uol.com.br> for the
Petal::Hash::Encode_HTML he contributed.


=head1 SEE ALSO

Join the Petal mailing list:

  http://lists.webarch.co.uk/mailman/listinfo/petal

Have a peek at the TAL / TALES / METAL specs:

  http://www.zope.org/Wikis/DevSite/Projects/ZPT/TAL
  http://www.zope.org/Wikis/DevSite/Projects/ZPT/TALES
  http://www.zope.org/Wikis/DevSite/Projects/ZPT/METAL

Any extra questions? jhiver@mkdoc.com

=cut
