=head1 NAME

Petal::Cache::Disk - Caches generated code on disk.

=head1 SYNOPSIS

  use Petal::Cache::Disk;
  my $data = Petal::Cache::Disk->get ('foo.html');
  unless (defined $data)
  {
    $data = complicated_long_compute_thing();
    Petal::Cache::Disk->set ($data);
  }

=head1 DESCRIPTION

  A simple cache module to avoid re-generating the Perl code from the
template file every time

=cut
package Petal::Cache::Disk;
use strict;
use warnings;
use File::Spec;
use Digest::MD5 qw /md5_hex/;
use Carp;


=head1 GLOBALS

=head2 $TMP_DIR

Temp directory in which to store the cached file. If left to undef,
File::Spec->tmpdir will be used instead.

=head2 $PREFIX

Name that should prefix the cached files. By default, set to 'petal_cache_',
i.e. 'foo.html' might be stored as petal_cache_4e38e18f1c6bedaaf174f95310a938c2

=cut
our $TMP_DIR = File::Spec->tmpdir;
our $PREFIX  = 'petal_cache';


=head1 METHODS

All the methods are static methods.

=head2 $class->get ($file);

Returns the cached data if its last modification time is more
recent than the last modification time of the template
Returns the code for template file $file, undef otherwise

=cut
sub get
{
    my $class = shift;
    my $file  = shift;
    my $key   = $class->compute_key ($file);
    return $class->cached ($key) if ($class->is_ok ($file));
    return;
}


=head2 $class->set ($file, $data);

Sets the cached data for $file.

=cut
sub set
{
    my $class = shift;
    my $file  = shift;
    my $data  = shift;
    my $key   = $class->compute_key ($file);
    my $tmp   = $class->tmp;
    open FP, ">$tmp/$key" or
        ( Carp::cluck "Cannot write-open $tmp/$key" and return );
    print FP $data;
    close FP;
}


=head2 $class->is_ok ($file);

Returns TRUE if the cache is still fresh, FALSE otherwise.

=cut
sub is_ok
{
    my $class = shift;
    my $file  = shift;
    
    my $key = $class->compute_key ($file);
    my $tmp = $class->tmp;    
    my $tmp_file = "$tmp/$key";
    return unless (-e $tmp_file);
    
    my $cached_mtime = $class->cached_mtime ($file);
    my $current_mtime = $class->current_mtime ($file);
    return $cached_mtime >= $current_mtime;
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
    # $file = File::Spec->rel2abs ($file);
    
    my $key = md5_hex ($file);
    $key = $PREFIX . "_" . $Petal::VERSION . "_" . $key if (defined $PREFIX);
    return $key;
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
    my $tmp = $class->tmp;
    
    my $tmp_file = "$tmp/$key";
    my $mtime = (stat($tmp_file))[9];
    return $mtime;
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


=head2 $class->cached ($key);

Returns the cached data for $key

=cut
sub cached
{
    my $class = shift;
    my $key = shift;
    my $tmp = $class->tmp;
    my $cached_filepath = $tmp . '/' . $key;
    
    (-e $cached_filepath) or return;
    
    open FP, "<$tmp/$key" or
        (Carp::cluck "Cannot read-open cached file for $tmp/$key" and return);
    my $data = join '', <FP>;
    close FP;
    
    return $data;
}


=head2 $class->tmp;

Returns the temp directory in which the cached data is kept

=cut
sub tmp
{
    my $class = shift;
    $TMP_DIR ||= File::Spec->tmpdir;
    
    (-e $TMP_DIR) or confess "\$TMP_DIR '$TMP_DIR' does not exist";
    (-d $TMP_DIR) or confess "\$TMP_DIR '$TMP_DIR' is not a directory";
    $TMP_DIR =~ s/\/+$//;
    return $TMP_DIR;
}


1;


__END__


=head1 AUTHOR

Jean-Michel Hiver <jhiver@mkdoc.com>

This module is redistributed under the same license as Perl itself.

=cut
