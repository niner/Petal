# ------------------------------------------------------------------
# Petal - Perl Template Attribute Language
# ------------------------------------------------------------------
# Author: Jean-Michel Hiver
# Description: Front-end for all Petal templating functionality
# ------------------------------------------------------------------
package Petal;
use Petal::Hash;
use Petal::CodeGenerator;
use Petal::Cache::Disk;
use Petal::Cache::Memory;
use Petal::Parser::XMLWrapper;
use Petal::Parser::HTMLWrapper;
use Petal::Canonicalizer::XML;
use Petal::Canonicalizer::XHTML;
use Petal::Functions;
use File::Spec;
use strict;
use warnings;
use Carp;
use Safe;


# these are used as local variables when the XML::Parser
# is crunching templates...
use vars qw /@tokens @nodeStack/;


# What do we use to parse input?
our $INPUT  = 'XML';
our $INPUTS = {
    'XML'   => 'Petal::Parser::XMLWrapper',
    'HTML'  => 'Petal::Parser::HTMLWrapper',
    'XHTML' => 'Petal::Parser::HTMLWrapper',
};


# What do we use to format output?
our $OUTPUT  = 'XML';
our $OUTPUTS = {
    'XML'   => 'Petal::Canonicalizer::XML',
    'HTML'  => 'Petal::Canonicalizer::XHTML',
    'XHTML' => 'Petal::Canonicalizer::XHTML',
};


# makes taint mode happy if set to 1
our $TAINT = undef;


# where are our templates supposed to be?
our @BASE_DIR = ('.');
our $BASE_DIR = undef; # for backwards compatibility...


# vroom!
our $DISK_CACHE = 1;


# vroom vroom!
our $MEMORY_CACHE = 1;


# prevents infinites includes...
our $MAX_INCLUDES = 30;
our $CURRENT_INCLUDES = 0;


# that's for CPAN
our $VERSION = '0.91';


# The CodeGenerator class backend to use.
# Change this only if you know what you're doing.
our $CodeGenerator = 'Petal::CodeGenerator';


# Default language for multi-language mode.
# Change if you feel that English isn't a fair default.
our $LANGUAGE = 'en';


# this is for XML namespace support. Can't touch this :-)
our $NS = 'petal';
our $NS_URI = 'http://purl.org/petal/1.0/';

our $XI_NS = 'xi';
our $XI_NS_URI = 'http://www.w3.org/2001/XInclude';


# Displays the canonical template for template.xml.
# You can set $INPUT using by setting the PETAL_INPUT environment variable.
# You can set $OUTPUT using by setting the PETAL_OUTPUT environment variable.
sub main::canonical
{
    my $file = shift (@ARGV);
    local $Petal::DISK_CACHE = 0;
    local $Petal::MEMORY_CACHE = 0;
    local $Petal::INPUT  = $ENV{PETAL_INPUT}  || 'XML';
    local $Petal::OUTPUT = $ENV{PETAL_OUTPUT} || 'XHTML';
    print ${Petal->new ($file)->_canonicalize()};
}


# Displays the perl code for template.xml.
# You can set $INPUT using by setting the PETAL_INPUT environment variable.
# You can set $OUTPUT using by setting the PETAL_OUTPUT environment variable.
sub main::code
{
    my $file = shift (@ARGV);
    local $Petal::DISK_CACHE = 0;
    local $Petal::MEMORY_CACHE = 0;
    print Petal->new ($file)->_code_disk_cached;
}


# Displays the perl code for template.xml, with line numbers.
# You can set $INPUT using by setting the PETAL_INPUT environment variable.
# You can set $OUTPUT using by setting the PETAL_OUTPUT environment variable.
sub main::lcode
{
    my $file = shift (@ARGV);
    local $Petal::DISK_CACHE = 0;
    local $Petal::MEMORY_CACHE = 0;
    print Petal->new ($file)->_code_with_line_numbers;
}


# Instanciates a new Petal object.
sub new
{
    my $class = shift;
    $class = ref $class || $class;
    unshift (@_, 'file') if (@_ == 1);
    my $self = bless { @_ }, $class;
    $self->_initialize();
    
    return $self;
}


# (multi language mode)
# if the language has been specified, let's try to
# find which template we can use.
sub _initialize
{
    my $self = shift;
    my $lang = $self->language() || return;

    my @dirs = @BASE_DIR;
    unshift (@dirs, $BASE_DIR) if (defined $BASE_DIR);
    @dirs = map { "$_/$self->{file}" } @dirs;

    $self->{file} =~ s/\/$//;
    my $filename = Petal::Functions::find_filename ($lang, @dirs) ||
        confess "Could not find language template for $lang";
    
    $self->{file} .= "/$filename";
}


# (multi language mode)
# returns the current preferred language.
sub language
{
    my $self = shift;
    return $self->{language} || $self->{lang};
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
    
    my $path = $self->{file};
    ($path)  = $path =~ /(.*)\/.*/;
    $path  ||= '.';
    $path .= '/';
    $path .= $file;
    
    my @path = split /\//, $path;
    my @new_path = ();
    while (scalar @path)
    {
	my $next = shift (@path);
	next if $next eq '.';
	
	if ($next eq '..')
	{
	    die "Cannot go above base directory: $file" if (scalar @new_path == 0);
	    pop (@new_path);
	    next;
	}
	
	push @new_path, $next;
    }
    
    return join '/', @new_path;
}


# Processes the current template object with the information contained in
# %hash. This information can be scalars, hash references, array
# references or objects.
#
# Example:
#
#   my $data_out = $template->process (
#     user   => $user,
#     page   => $page,
#     basket => $shopping_basket,    
#   );
#
# print "Content-Type: text/html\n\n";
# print $data_out;
sub process
{
    # prevent infinite includes from happening...
    my $current_includes = $CURRENT_INCLUDES;
    local $CURRENT_INCLUDES = $current_includes + 1;
    return "ERROR: MAX_INCLUDES : $CURRENT_INCLUDES" if ($CURRENT_INCLUDES >= $MAX_INCLUDES);
    
    my $self = shift;
    my $hash = undef;
    if (ref $_[0] eq 'Petal::Hash') { $hash = shift }
    elsif (ref $_[0] eq 'HASH')     { $hash = new Petal::Hash (%{shift()}) }
    else                            { $hash = new Petal::Hash (@_)         }
    
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
    my @dirs = @BASE_DIR;
    unshift (@dirs, $BASE_DIR) if (defined $BASE_DIR);
    
    foreach my $dir (@dirs)
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
	$data_ref    = $self->_canonicalize;
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
