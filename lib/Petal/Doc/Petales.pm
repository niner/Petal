package Petal::Doc::Petales;
use strict;
use warnings;


1;


__END__

=head1 NAME

Petal::Doc::Petales - Petal Expression Syntax

=head1 SYNOPSIS

This is an article, not a module.

=head1 SUMMARY

Petal has the ability to bind template variables to the following Perl
datatypes: scalars, lists, hash, arrays and objects. The article describes
the syntax which is used to access these from Petal templates.

In the following examples, we'll assume that the template is used as follows:

  my $hashref = some_complex_data_structure();
  my $template = new Petal ('foo.xml');
  print $template->process ( $hashref );

Then we will show how the Petal Expression Syntax maps to the Perl way of
accessing these values.  


=head1 BASIC SYNTAX


=head2 Accessing scalar values

=head3 Perl expression

  $hashref->{'some_value'};

=head3 Petal expression

  some_value

=head3 Example

  <!--? Replaces Hello, World with the contents of
        $hashref->{'some_value'}
  -->
  <span petal:replace="some_value">Hello, World</span>


=head2 Accessing hashes & arrays

=head3 Perl expression

  $hashref->{'some_hash'}->{'a_key'};

=head3 Petal expression

  some_hash/a_key

=head3 Example

  <!--? Replaces Hello, World with the contents
        of $hashref->{'some_hash'}->{'a_key'}
  -->
  <span petal:replace="some_hash/a_key">Hello, World</span>


=head3 Perl expression

  $hashref->{'some_array'}->[12]

=head3 Petal expression

  some_array/12

=head3 Example

  <!-- Replaces Hello, World with the contents
       of $hashref->{'some_array'}->[12]
  -->
  <span petal:replace="some_array/12">Hello, World</span>

Note: You're more likely to want to loop through arrays:

  <!-- Loops trough the array and displays each values -->
  <ul petal:condition="some_array">
    <li petal:repeat="value some_array"
        petal:content="value">Hello, World</li>
  </ul>


=head2 Accessing object methods

=head3 Perl expressions

  1. $hashref->{'some_object'}->some_method();
  2. $hashref->{'some_object'}->some_method ('foo', 'bar');
  3. $hashref->{'some_object'}->some_method ($hashref->{'some_variable')  

=head3 Petal expressions

  1. some_object/some_method
  2a. some_object/some_method 'foo' 'bar'
  2b. some_object/some_method "foo" "bar"
  2c. some_object/some_method --foo --bar
  3. some_object/some_method some_variable

Note that the syntax as described in 2c works only if you use strings
which do not have spaces.

=head3 Example

  <p>
    <span petal:replace="value1">2</span> times
    <span petal:replace="value2">2</span> equals
    <span petal:replace="math_object/multiply value1 value2">4</span>
  </p>
    

=head2 Composing

Petal lets you traverse any data structure, i.e.

=head3 Perl expression

  $hashref->{'some_object'}
          ->some_method()
          ->{'key2'}
          ->some_other_method ( 'foo', $hash->{bar} );

=head3 Petal expression

  some_object/some_method/key2/some_other_method 'foo' bar


=head1 MODIFIERS

Petal features 'expression modifiers'. Expression modifiers are either
modules or coderefs that can be used to alter the result of an expression.

By default, the following modifiers are supported:


=head2 true:EXPRESSION

  If EXPRESSION returns an array reference
    If this array reference has at least one element
      Returns TRUE
    Else
      Returns FALSE

  Else
    If EXPRESSION returns a TRUE value (according to Perl 'trueness')
      Returns TRUE
    Else
      Returns FALSE

the true: modifiers should always be used when doing Petal conditions.


=head2 false:EXPRESSION

I'm sure you can work that out by yourself :-)


=head2 set:variable_name EXPRESSION

Sets the value returned by the evaluation of EXPRESSION in
$hash->{variable_name}. For instance:

Perl expression:

  $hash->{variable_name} = $hash->{object}->method();

Petal expression:

  set:variable_name object/method


=head2 string:STRING_EXPRESSION

The string: modifier lets you interpolate petal expressions
within a string and returns the value.

  string:Welcome $user/real_name, it is $date!

Alternatively, you could write:

  string:Welcome ${user/real_name}, it is ${date}!
  
The advantage of using curly brackets is that it lets you
interpolate expressions which invoke methods with parameters,
i.e.

  string:The current CGI 'action' param is: ${cgi/param --action}


=head1 WRITING YOUR OWN MODIFIERS

Petal lets you write your own modifiers, either using coderefs
or modules.


=head2 Using coderefs

Let's say that you want to write an uppercase: modifier, which
would uppercase the result of an expression evaluation, as in:

  uppercase:string:Hello, World

Would return

  HELLO, WORLD

Here is what you can do:

  # don't forget the colon!!
  $Petal::Hash::MODIFIERS->{'uppercase:'} = sub {
      my $hash = shift;
      my $args = shift;
      my $result = $hash->fetch ($args);
      return uc ($result);
  };


=head2 Using modules

For quite big modifiers, you might want to use a module rather
than a coderef. Here is the example above reimplemented as a
module:

  package MyPetalModifier::UpperCase;
  use strict;
  use warnings;
  
  sub process {
    my $class = shift;
    my $hash  = shift;
    my $args  = shift;

    my $result = $hash->fetch ($args);
    return uc ($result);
  }

  1;

You need to make Petal aware of the existence of the module, which
you do as follows:

  $Petal::Hash::MODIFIERS->{'uppercase:'} = 'MyPetalModifier::UpperCase';


=head1 Expression keywords


=head2 XML encoding / structure keyword

By default Petal will encode &, <, > and " to &amp; &lt;, &gt and &quot;
respectively. However sometimes you might want to display an expression which
is already encoded, in which case you can use the 'structure' keyword.

  structure my/encoded/variable


=head2 Petal::Hash caching and fresh keyword 

Petal caches the expressions which it resolves, i.e. if you write the
expression:

  string:$foo/bar, ${baz/buz/blah}

Petal::Hash will compute it once, and then for subsequent accesses to that
expression always return the same value. This is almost never a problem, even
for loops because a new Petal::Hash object is used for each iteration in order
to support proper scoping.

However, in some rare cases you might not want to have that behavior, in which
case you need to prefix your expression with the 'fresh' keyword, i.e. 

  fresh string:$foo/bar, ${baz/buz/blah}

You can use 'fresh' with 'structure' if you need to:

  fresh structure string:$foo/bar, ${baz/buz/blah}

However the reverse does not work:

  structure fresh string:$foo/bar, ${baz/buz/blah}  <!-- VERY BAD, WON'T WORK !!! -->


=head1 AUTHOR

Copyright 2002 - Jean-Michel Hiver <jhiver@mkdoc.com> 

This module is free software and is distributed under the
same license as Perl itself.
