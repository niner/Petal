package Petal::Syntax::PIs;
use strict;
use warnings;


1;


__END__


=head1 NAME

Petal::Syntax::PIs - Processing Instructions Syntax


=head1 SYNOPSIS

This is an article, not a module.


=head1 SUMMARY

This syntax is used by Petal as a 'canonical' syntax, i.e. both
Inline and TAL syntaxes are turned into processing instructions.

It is quite similar to HTML::Template or the Template Toolkit
syntaxes and it is quite easy to turn into Perl code.


=head1 NAMESPACE

Petal processing instructions used to be prefixed by petal:. Since
processing instructions are not meant to support XML namespaces, this
has been removed.


=head1 STATEMENTS


=head2 Variables

=head3 Abstract

  <?var name="EXPRESSION"?>

=head3 Example

  <title><?var name="document/title"?></title>

=head3 Why?

Because if you don't have things which are replaced by real values
in your template, it's probably a static page, not a template :-)


=head2 If / Else constructs

Usual stuff:

  <?if name="user/is_birthay"?>
    Happy Birthday, $user/real_name!
  <?else?>
    What?! It's not your birthday?
    A very merry unbirthday to you! 
  <?end?>

You can use petal:condition instead of petal:if, and indeed you
can use modifiers:

  <?condition name="false:user/is_birthay"?>
    What?! It's not your birthday?
    A very merry unbirthday to you! 
  <?else?>
    Happy Birthday, $user/real_name!
  <?end?>

Not much else to say!


=head3 Loops

Use either petal:for, petal:foreach, petal:loop or petal:repeat. They're
all the same thing, which one you use is a matter of taste. Again no
surprise:

  <h1>Listing of user logins</h1>
  <ul>
    <?repeat name="user system/list_users"?>
      <li><?var name="user/login"?> :
          <?var name="user/real_name"?></li>
    <?end?>
  </ul>
  

Variables are scoped inside loops so you don't risk to erase an existing
'user' variable which would be outside the loop. The template engine
also provides the following variables for you inside the loop:

  <?repeat name="foo bar"?>
    <?var name="__count__"?>    - iteration number, starting at 1
    <?var name="__is_first__"?> - is it the first iteration
    <?var name="__is_last__"?>  - is it the last iteration
    <?var name="__is_inner__"?> - is it not the first and not the last iteration
    <?var name="__even__ "?>    - is the count even
    <?var name="__odd__"?>      - is the count odd
  <?end?>

Again these variables are scoped, you can safely nest loops, ifs etc...
as much as you like and everything should be fine. And if it's not,
it's a bug :-)


=head1 Includes

At the moment this is the only way to do includes with Petal.
Limited support for XIncludes is planned for the future.

  <?include file="include.xml"?>

And it will include the file 'include.xml', using the current object
base_dir attribute. Petal includes occur at RUN TIME. That means that
there is NO SUPPORT to prevent infinite includes, which is usually not
so much of a deal since they happen at run time...

This should let you build templates which have a recursive behavior
which can be useful to apply templates to any tree-shaped structure (i.e.
sitemaps, threads, etc).

If you want use XML::Parser to include files, you should make sure that
the included files are valid XML themselves... FYI XML::Parser chokes on
this:

<p>foo</p>
<p>bar</p>

But this works:

<div>
  <p>foo</p>
  <p>bar</p>
</div>

(having only one top element is part of the XML spec).


=head1 AUTHOR

Copyright 2002 - Jean-Michel Hiver <jhiver@mkdoc.com> 

This module is free software and is distributed under the
same license as Perl itself.

=cut
