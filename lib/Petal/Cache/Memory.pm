=head1 NAME

Petal::Cache::Memory - Caches generated subroutines in memory.

=head1 SYNOPSIS

  use Petal::Cache::Memory;
  my $coderef = Petal::Cache::Memory->get ('foo.html');
  unless (defined $coderef)
  {
    $coderef = complicated_long_compute_thing();
    Petal::Cache::Memory->set ($coderef);
  }

=head1 DESCRIPTION

  A simple cache module to avoid re-compiling the Perl
  code from the Perl data at each request

=cut
package Petal::Cache::Memory;
use strict;
use warnings;
use Carp;

our $FILE_TO_SUBS  = {};
our $FILE_TO_MTIME = {};


sub sillyness
{
    + $Petal::INPUT && $Petal::OUTPUT;
}


=head1 METHODS

All the methods are static methods.

=head2 $class->get ($file);

Returns the cached subroutine if its last modification time
is more recent than the last modification time of the template,
returns undef otherwise

=cut
sub get
{
    my $class = shift;
    my $file  = shift;
    my $key = $class->compute_key ($file);
    my $data  = shift;
    return $FILE_TO_SUBS->{$key} if ($class->is_ok ($file));
    return;
}


=head2 $class->set ($file, $code);

Sets the cached code for $file.

=cut
sub set
{
    my $class = shift;
    my $file  = shift;
    my $key = $class->compute_key ($file);
    my $code  = shift;
    $FILE_TO_SUBS->{$key} = $code;
    $FILE_TO_MTIME->{$key} = $class->current_mtime ($file);
}


=head2 $class->is_ok ($file);

Returns TRUE if the cache is still fresh, FALSE otherwise.

=cut
sub is_ok
{
    my $class = shift;
    my $file  = shift;
    my $key = $class->compute_key ($file);
    return unless (defined $FILE_TO_SUBS->{$key});
    
    my $cached_mtime = $class->cached_mtime ($file);
    my $current_mtime = $class->current_mtime ($file);
    return $cached_mtime >= $current_mtime;
}


=head2 $class->cached_mtime ($file);

Returns the last modification date of the cached data
for $file

=cut
sub cached_mtime
{
    my $class = shift;
    my $file = shift;
    my $key = $class->compute_key ($file);
    return $FILE_TO_MTIME->{$key};
}


=head2 $class->current_mtime ($file);

Returns the last modification date for $file

=cut
sub current_mtime
{
    my $class = shift;
    my $file = shift;
    my $mtime = (stat($file))[9];
    return $mtime;
}


=head2 $class->compute_key ($file);

Computes a cache 'key' for $file, which should be unique.
(Well, currently an MD5 checksum is used, which is not
*exactly* unique but which should be good enough)

=cut
sub compute_key
{
    my $class = shift;
    my $file = shift;
    
    my $key = $file . ";INPUT=" . $Petal::INPUT . ";OUTPUT=" . $Petal::OUTPUT;
    return $key;
}


1;


__END__


=head1 AUTHOR

Jean-Michel Hiver <jhiver@mkdoc.com>

This module is redistributed under the same license as Perl itself.

=cut
