=head1 NAME

Petal::Hash - Magical hash for Petal objects


=head1 SYNOPSIS

  my $object = new My::WonderfulObject;
  my $hash   = new Petal::Hash (
    object => $object,
    time   => time()
  );

  # invokes $object->some_method();
  $hash->{'object.some_method'};

  # invokes $object->other_method ('foo', 'bar');
  $hash->{'object.other_method foo bar'};

  # invokes $object->other_method ($hash->{'time'});
  $hash->{'object.other_method $time'}

  # invokes $object->foo() and returns the XML-encoded results
  $hash->{':xml foo'}

  # is $object->foo() true?
  $hash->{':true foo'}

  # is $object->foo() false?
  $hash->{':false foo'}

  # finally, these two lines are *EXACTLY* the same:
  $hash->{foo} = $hash->{'object.bar'};
  $hash->{':set foo object.bar'};


=head1 DESCRIPTION

Petal::Hash turns a hash into a much more powerful black
magic powered structure which can invoke object methods, encode the
method results to XML, etc. etc. using the various Petal::Hash::*
modules.


=head1 EXTENDING

Let's say you want to build a modifier that returns the length of a string,
so that you could do:

  $hash->{string} = 'foo';
  print $hash->{':length foo'};

You would write the following module:

  package MyMod::Length;
  use base qw /Petal::Hash::VAR/;

  sub process
  {
      my $class = shift;
      my $self = shift;
      my $argument = shift;

      my $value = $self->SUPER::process ($self, join ' ', @split);
      return length ($value);
  }

And at the beginning of your program do:

  $Petal::Hash::MODIFIERS->{length} = 'MyMod::Length';

And that's it! Easy, huh?


=head1 AUTHOR

Jean-Michel Hiver <jhiver@mkdoc.com>

This module is redistributed under the same license as Perl itself.


=head1 SEE ALSO

The standard modifier modules:

  Petal::Hash::VAR
  Petal::Hash::SET
  Petal::Hash::TRUE
  Petal::Hash::FALSE
  Petal::Hash::Encode_XML

=cut
package Petal::Hash;
use strict;
use warnings;
use Carp;

use Petal::Hash::VAR;
use Petal::Hash::SET;
use Petal::Hash::TRUE;
use Petal::Hash::FALSE;
use Petal::Hash::Encode_XML;
use Petal::Hash::Encode_HTML;
use Petal::Hash::UpperCase;
use Petal::Hash::String;


our $IMPORTED  = {
    'Petal::Hash::VAR'         => 1,
    'Petal::Hash::Encode_XML'  => 1,
    'Petal::Hash::TRUE'        => 1,
    'Petal::Hash::FALSE'       => 1,
    'Petal::Hash::SET'         => 1,
    'Petal::Hash::Encode_HTML' => 1,
    'Petal::Hash::String'      => 1,
};


our $MODIFIERS = {
    "uc:"          => 'Petal::Hash::UpperCase',
    "var:"         => 'Petal::Hash::VAR',
    "xml:"         => 'Petal::Hash::Encode_XML',
    "encode:"      => \'xml:',
    "true:"        => 'Petal::Hash::TRUE',
    "false:"       => 'Petal::Hash::FALSE',
    "set:"         => 'Petal::Hash::SET',
    "def:"         => \'set:',
    "define:"      => \'define:',
    "html:"        => 'Petal::Hash::Encode_HTML',
    "encode_html:" => \'html:',
    "string:"      => 'Petal::Hash::String',
};


sub new
{
    my $class = shift;
    my %hash = ();
    tie %hash, $class;
    %hash = @_;
    
    return \%hash;
}


sub TIEHASH  { bless {}, $_[0] }
sub STORE    { $_[0]->{$_[1]} = $_[2] }
sub FIRSTKEY { my $a = scalar keys %{$_[0]}; each %{$_[0]} }
sub NEXTKEY  { each %{$_[0]} }
sub EXISTS   { exists $_[0]->{$_[1]} }
sub DELETE   { delete $_[0]->{$_[1]} }
sub CLEAR    { %{$_[0]} = () }


sub FETCH
{
    my $self = shift;
    my $key  = shift;
    my $mod  = 'var:';
    
    foreach my $modifier (keys %{$MODIFIERS})
    {
	if ($key =~ /^\Q$modifier\E/)
	{    
	    $mod = $modifier;
	    $key =~ s/^\Q$modifier\E//;
	    last;
	}
    }
    
    my $module = $MODIFIERS->{$mod};
    while (ref $module) { $module = $MODIFIERS->{$$module} }
    
    confess "$mod is not a known modifier" unless (defined $module);
    unless (defined $IMPORTED->{$module})
    {
	eval "use $module";
	(defined $@ and $@) and
	    confess "cannot import $module for modifier $mod";
	$IMPORTED->{$module} = 1;
    }
    
    $key =~ s/^\s+//;
    $module->process ($self, $key);
}


1;


__END__
