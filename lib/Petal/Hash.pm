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
    my $variable = $hash->fetch (@_);
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
    my $thing = shift;
    my $class = ref $thing || $thing;
    
    my $self  = bless { @_ }, $class;
    $self->{__petal_hash_cache__}  = {};
    $self->{__petal_hash_parent__} = (ref $thing) ? $thing : undef;
    return $self;
}


# Gets a value...
sub get
{
    my $self   = shift;
    my $key    = shift;
    my $fresh  = $key =~ s/^\s*fresh\s+//;
    delete $self->{__petal_hash_cache__}->{$key} if ($fresh);
    exists $self->{__petal_hash_cache__}->{$key} and return $self->{__petal_hash_cache__}->{$key};
    
    my $parent = $self->parent();
    my $res    = $self->__FETCH ($key);
    $res = $parent->get ($key) if (not defined $res and defined $parent);
    $self->{__petal_hash_cache__}->{$key} = $res;
    return $res;
}


sub parent
{
    my $self = shift;
    return $self->{__petal_hash_parent__};
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
    
    my $mod  = $self->_fetch_mod ($key);
    $key =~ s/^\Q$mod\E//;
    $key =~ s/^\s+//;
    
    my $module = $MODIFIERS->{$mod} || confess "$mod is not a known modifier";
    (defined $module and ref $module and ref $module eq 'CODE') and return $module->($self, $key);
    
    $IMPORTED->{$module} ||= do {
	eval "use $module";
	(defined $@ and $@) and confess "cannot import $module for modifier $mod";
	1;
    };
    
    $module->process ($self, $key);
}


sub _fetch_mod
{
    my $self  = shift;
    my $key   = shift;
    my ($mod) = $key =~ /^(\S+?\:).*/;
    defined $mod || return 'var:';
    return (defined $MODIFIERS->{$mod}) ? $mod : 'var:';
}


1;


__END__
