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


=head1 NAMESPACE

Although this is not mandatory, Petal templates should include use the namespace
http://purl.org/petal/1.0/, preferably as an attribute of the first element
of the XML template which you are processing.

Example:

    <html xml:lang="en"
          lang="en-"
          xmlns="http://www.w3.org/1999/xhtml"
          xmlns:petal="http://purl.org/petal/1.0/">

      Blah blah blah...
      Content of the file
      More blah blah...
    </html>

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

$DISK_CACHE  - If set to FALSE, Petal will not use the Petal::Cache::Disk module. Defaults to TRUE.

=cut
our $DISK_CACHE = 1;


=pod

$MEMORY_CACHE - If set to FALSE, Petal will not use the Petal::Cache::Memory module. Defaults to TRUE.

=cut
our $MEMORY_CACHE = 1;


=pod

$MAX_INCLUDES - Maximum number of recursive includes before Petal stops processing.
This is to prevent from accidental infinite recursions.

=cut
our $MAX_INCLUDES = 30;
our $CURRENT_INCLUDES = 0;

our $VERSION = '0.86';


=pod

$CodeGenerator - The CodeGenerator class backend to use. Change this only if you
know what you're doing.

=cut

our $CodeGenerator = 'Petal::CodeGenerator';


# this is for XML namespace support. Can't touch this :-)
our $NS = 'petal';
our $NS_URI = 'http://purl.org/petal/1.0/';

our $XI_NS = 'xi';
our $XI_NS_URI = 'http://www.w3.org/2001/XInclude';


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


=head1 TOY FUNCTIONS (For debugging or if you're curious)

=head2 perl -MPetal -e canonical template.xml

Displays the canonical template for template.xml.
You can set $INPUT using by setting the PETAL_INPUT environment variable.
You can set $OUTPUT using by setting the PETAL_OUTPUT environment variable.

=cut
sub main::canonical
{
    my $file = shift (@ARGV);
    local $Petal::DISK_CACHE = 0;
    local $Petal::MEMORY_CACHE = 0;
    local $Petal::INPUT  = $ENV{PETAL_INPUT}  || 'XML';
    local $Petal::OUTPUT = $ENV{PETAL_OUTPUT} || 'XHTML';
    print ${Petal->new ($file)->_canonicalize()};
}


=head2 perl -MPetal -e code template.xml

Displays the perl code for template.xml.
You can set $INPUT using by setting the PETAL_INPUT environment variable.
You can set $OUTPUT using by setting the PETAL_OUTPUT environment variable.

=cut
sub main::code
{
    my $file = shift (@ARGV);
    local $Petal::DISK_CACHE = 0;
    local $Petal::MEMORY_CACHE = 0;
    print Petal->new ($file)->_code_disk_cached;
}


=head2 perl -MPetal -e lcode template.xml

Displays the perl code for template.xml, with line numbers.
You can set $INPUT using by setting the PETAL_INPUT environment variable.
You can set $OUTPUT using by setting the PETAL_OUTPUT environment variable.

=cut
sub main::lcode
{
    my $file = shift (@ARGV);
    local $Petal::DISK_CACHE = 0;
    local $Petal::MEMORY_CACHE = 0;
    print Petal->new ($file)->_code_with_line_numbers;
}


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


# _include_compute_path ($path);
# ------------------------------
# Computes the new absolute path from the current
# path and $path
sub _include_compute_path
{
    my $self  = shift;
    my $file  = shift;
    return $file unless ($file =~ /^\./);
    
    my $path1 = $self->{file};
    $path1 =~ s/^\///;
    my @path1 = split /\//, $path1;
    pop (@path1); # get old filename out of the way
    
    my $path2 = $file;
    my @path2 = split /\//, $path2;
    
    my @path = (@path1, @path2);
    my @new_path = ();
    while (@path)
    {
	my $dir = shift (@path);
	next if ($dir) eq '.';
	
	if ($dir eq '..')
	{
	    confess "Cannot include $file: Cannot go above base directory"
	    unless (scalar @new_path);
	    
	    pop (@new_path);
	}
	else
	{
	    push @new_path, $dir;
	}
    }
    
    my $res = '/' . join '/', @new_path;
    return $res;
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
    # prevent infinite includes from happening...
    my $current_includes = $CURRENT_INCLUDES;
    local $CURRENT_INCLUDES = $current_includes + 1;
    return "ERROR: MAX_INCLUDES : $CURRENT_INCLUDES" if ($CURRENT_INCLUDES >= $MAX_INCLUDES);
    
    my $self = shift;
    my $hash = undef;
    if (@_ == 1 and ref $_[0] eq 'HASH')
    {
	my $tied = tied %{$_[0]};
	if ($tied and ref $tied eq 'Petal::Hash')
	{
	    $hash = new Petal::Hash (%{$tied});
	}
	else
	{
	    $hash = new Petal::Hash (%{$_[0]});
	}
    }
    else
    {
	$hash = new Petal::Hash (@_);
    }
    
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
      "${line_num}. ${cur_line}";
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
	$code = $CodeGenerator->process ($data_ref, $self);
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
	    $cpt->permit ('entereval');
	    $cpt->permit ('leaveeval');
	    
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

=head1 Template cycle

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

  <!--? This will not be in the output -->


=head2 "Simple" syntax (Variable Interpolation)

  $my_variable
  $my_object/my_method
  $my_array/2
  $my_hash/some_key

This syntax is documented in the L<Petal::Doc::Inline>
article.


=head2 "TAL-like" syntax, i.e.

  <li petal:repeat="element list"
      petal:content="element">Some dummy element</li>

Which if 'list' was ('foo', 'bar', 'baz') would output:

  <li>foo</li>
  <li>bar</li>
  <li>baz</li>

This syntax is documented in the L<Petal::Doc::TAL>
article.


=head2 "Usual" syntax (like HTML::Template, Template::Toolkit, etc), i.e

  <?condition name="list"?>
    <?repeat name="element list"?>
      <li><?var name="element"?></li>
    <?end?>
  <?end?>

This syntax is documented in the L<Petal::Doc::PIs>
article.


=head2 Limited Xinclude support

Let's say that your base directory is '/www/projects/foo/templates',
and you're editing '/www/projects/foo/templates/hello/index.html'.

From there you want to include '/www/projects/foo/templates/includes/header.html'


=head3 General syntax

You can use a subset of the XInclude syntax as follows:

  <body xmlns:xi="http://www.w3.org/2001/XInclude">
    <xi:include href="/includes/header.html" />
  </body>


For backwards compatibility reasons, you can omit the first slash, i.e.

  <xi:include href="includes/header.html" />


=head3 Relative paths

If you'd rather use a path which is relative to the template itself rather
than the base directory, you can do it but the path needs to start with a dot,
i.e.

  <xi:include href="../includes/header.html" />

  <xi:include href="./subdirectory/foo.xml" />

etc.

=head3 Limitations

The 'href' parameter does not support URIs, no other tag than
xi:include is supported, and no other directive than the 'href'
parameter is supported at the moment.

Also note that contrarily to the XInclude specification Petal DOES
allow recursive includes up to $Petal::MAX_INCLUDES. This behavior
is very useful when designing templates to display data which can
be recursive such as sitemaps, database cursors, fibonacci suites,
etc.

You can use ONLY the following Petal directives with Xinclude tags:

  * on-error
  * define
  * condition
  * repeat

replace, content, omit-tag and attributes are NOT supported in
conjunction with XIncludes.


=head1 Variable expressions and modifiers

Petal lets you transparently access arrays, hashes, objects, etc.
trough a unified syntax called Petales (Petal Expression Syntax).
It is documented in L<Petal::Doc::Petales>.


=head1 EXPORT

None.


=head1 KNOWN BUGS

The XML::Parser wrapper cannot expand any other entity than &lt;, &gt; &amp;
and &quot;. Besides, I can't get it to NOT expand entities in 'Stream' mode :-(

HTML::TreeBuilder expands all entities, hence &nbsp;s are lost / converted to
whitespaces.

XML::Parser is deprecated and should be replaced by SAX handlers at some point.


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

And everyone else I forgot :-)


=head1 SEE ALSO

Join the Petal mailing list:

  http://lists.webarch.co.uk/mailman/listinfo/petal

Mailing list archives:

  http://lists.webarch.co.uk/pipermail/petal


Have a peek at the TAL / TALES / METAL specs:

  http://www.zope.org/Wikis/DevSite/Projects/ZPT/TAL
  http://www.zope.org/Wikis/DevSite/Projects/ZPT/TALES
  http://www.zope.org/Wikis/DevSite/Projects/ZPT/METAL


Look at the different syntaxes which you can use:

L<Petal::Doc::Inline>,
L<Petal::Doc::PIs>,
L<Petal::Doc::TAL>,


And the expression syntax: L<Petal::Doc::Petales>.


Any extra questions? jhiver@mkdoc.com.

=cut
