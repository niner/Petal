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

  # is $object->foo() true?
  $hash->{'true:foo'}

  # is $object->foo() false?
  $hash->{'false:foo'}

  # finally, these two lines are *EXACTLY* the same:
  $hash->{foo} = $hash->{'object.bar'};
  $hash->{'set:foo object.bar'};


=head1 DESCRIPTION

Petal::Hash turns a hash into a much more powerful black
magic powered structure which can invoke object methods, encode the
method results to XML, etc. etc. using the various Petal::Hash::*
modules.


=head1 EXTENDING

Let's say you want to build a modifier that returns the length of a string,
so that you could do:

  $hash->{string} = 'foo';
  print $hash->{'length:foo'};

You would write the following module:

  package MyMod::Length;

  sub process
  {
      my $class = shift;
      my $hash  = shift;
      my $argument = shift;
      return length ($hash->fetch ($argument));
  }

And at the beginning of your program do:

  $Petal::Hash::MODIFIERS->{'length:'} = 'MyMod::Length';

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

=cut
package Petal::Hash;
use strict;
use warnings;
use Carp;

use Petal::Hash::Var;
use Petal::Hash::String;


# This hash lists all the modules which have
# been already imported.
our $IMPORTED  = {
    'Petal::Hash::Var'         => 1,
    'Petal::Hash::String'      => 1,
};


# This is the list of modifiers, i.e. modules
# which can be used to alter Petal expression
# evaluation.
our $MODIFIERS = {
    'var:'    => 'Petal::Hash::Var',
    'string:' => 'Petal::Hash::String',
};


# set modifier
$MODIFIERS->{'set:'} = sub {
    my $hash  = shift;
    my $argument = shift;
    my @split = split /\s+/, $argument;
    my $set   = shift (@split) or confess "bad syntax for 'set:': $argument (\$set)";
    my $value = $hash->fetch (join ' ', @split);
    $hash->{$set} = $value;
    return '';
};
$MODIFIERS->{'def:'}    = $MODIFIERS->{'set:'};
$MODIFIERS->{'define:'} = $MODIFIERS->{'set:'};


# true modifier
$MODIFIERS->{'true:'} = sub {
    my $hash = shift;
    my $variable = $hash->FETCH (@_);
    return unless (defined $variable);
    
    (scalar @{$variable}) ? return 1 : return
        if (ref $variable eq 'ARRAY' or (ref $variable and $variable =~ /=ARRAY\(/));
    
    ($variable) ? return 1 : return;
};


# false modifier
$MODIFIERS->{'false:'} = sub {
    my $hash = shift;
    my $variable = join ' ', @_;
    return not $hash->fetch ("true:$variable");
};


# encode: modifier (deprecated stuff)
$MODIFIERS->{'encode:'} = sub {
    warn "Petal modifier encode: is deprecated";
    my $hash = shift;
    my $argument = shift;
    return $hash->fetch ($argument);
};
$MODIFIERS->{'xml:'}         = $MODIFIERS->{'encode:'};
$MODIFIERS->{'html:'}        = $MODIFIERS->{'encode:'};
$MODIFIERS->{'encode_html:'} = $MODIFIERS->{'encode:'};



# Instanciates a new Petal::Hash object which should
# be tied to a hash.
sub new
{
    my $class = shift;
    my %hash = ();
    tie %hash, $class;
    %hash = @_;
    $hash{__petal_hash_cache__} = {};
    return \%hash;
}


# these are pretty straightforward, the only really interesting
# method is the FETCH method.
sub TIEHASH  { bless {}, $_[0] }
sub STORE    { $_[0]->{$_[1]} = $_[2] }
sub FIRSTKEY { my $a = scalar keys %{$_[0]}; each %{$_[0]} }
sub NEXTKEY  { each %{$_[0]} }
sub EXISTS   { exists $_[0]->{$_[1]} }
sub DELETE   { delete $_[0]->{$_[1]} }
sub CLEAR    { %{$_[0]} = () }


# The FETCH method returns the result of the evaluation of a given Petal
# statement. By default it encodes the 4 XML entities &amp; &lt; &gt; and
# &quot; unless the 'structure' keyword is used.
sub FETCH
{
    my $self = shift;
    my $key  = shift;
    
    my $fresh = $key =~ s/^\s*fresh\s+//;
    delete $self->{__petal_hash_cache__}->{$key} if ($fresh);
    $self->{__petal_hash_cache__}->{$key} ||= do { $self->__FETCH ($key) };
    return $self->{__petal_hash_cache__}->{$key};
}


sub __FETCH
{
    my $self = shift;
    my $key  = shift;
    my $no_encode = $key =~ s/^\s*structure\s+//;
    if (defined $no_encode and $no_encode)
    {
	return $self->fetch ($key);
    }
    else
    {
	$key =~ s/^\s*text\s*//;
	my $res = $self->fetch ($key);
	if (defined $res and not ref $res)
	{
	    $res = $self->_xml_encode ($res);
	}
	return $res;
    }
}


# encodes the 4 xml entities &amp; &lt; &gt; and &quot;.
sub _xml_encode
{
    my $self = shift;
    my $data = join '', @_;
    $data =~ s/\&/&amp;/g;
    $data =~ s/\</&lt;/g;
    $data =~ s/\>/&gt;/g;
    $data =~ s/\"/&quot;/g;
    return $data;
}


# this method fetches a Petal expression and returns it
# without XML encoding. FETCH is basically a wrapper around
# fetch() which looks for the special keyword 'structure'.
sub fetch
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
    
    $key =~ s/^\s+//;
    my $module = $MODIFIERS->{$mod};
    if (defined $module and ref $module and ref $module eq 'CODE')
    {
	return $module->($self, $key);
    }
    else
    {
	confess "$mod is not a known modifier" unless (defined $module);
	unless (defined $IMPORTED->{$module})
	{
	    eval "use $module";
	    (defined $@ and $@) and confess "cannot import $module for modifier $mod";
	    $IMPORTED->{$module} = 1;
	}
	$module->process ($self, $key);
    }
}


1;


__END__
