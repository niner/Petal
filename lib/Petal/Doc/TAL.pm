package Petal::Doc::TAL;
use strict;
use warnings;


1;


__END__


=head1 NAME

Petal::Doc::TAL - Template Attribute Language


=head1 SYNOPSIS

This is an article, not a module.


=head1 SUMMARY

This functionality is directly and shamelessly stolen from the excellent
TAL specification, which is available here:
http://www.zope.org/Wikis/DevSite/Projects/ZPT/TAL.


=head1 NAMESPACE

By default the prefix which is used by Petal is not tal:, but petal:.
If you want to change this, you need to declare the Petal namespace
as follows (for the sake of the example, let's say we want to use the
'TAL' prefix instead of 'petal'):

    <html xml:lang="en"
          lang="en-"
          xmlns="http://www.w3.org/1999/xhtml"
          xmlns:TAL="http://purl.org/petal/1.0/">

      Blah blah blah...
      Content of the file
      More blah blah...
    </html>


=head1 STATEMENTS

=head2 define

=head3 Abstract

  <tag petal:define="variable_name EXPRESSION">

Evaluates EXPRESSION and assigns the returned value
to variable_name.

=head3 Example

  <!-- sets document/title to 'title' -->
  <span petal:define="title document/title">

=head3 Why?

This can be useful if you have a 'very/very/long/expression'.
You can set it to let's say 'vvle' and then use 'vvle' instead
of using 'very/very/long/expression'.


=head2 condition (ifs)

=head3 Abstract

  <tag petal:condition="true:EXPRESSION">
     blah blah blah
  </tag>

=head3 Example

  <span petal:condition="true:user/is_authenticated">
    Yo, authenticated!
  </span>

=head3 Why?

Conditions can be used to display something if an expression
is true. They can also be used to check that a list exists
before attempting to loop through it.


=head2 repeat (loops)

=head3 Abstract

  <tag petal:repeat="element_name EXPRESSION">
     blah blah blah
  </tag>

=head3 Example

  <li petal:repeat="user system/user_list">$user/real_name</li>

=head3 Why?

Repeat statements are used to loop through a list of values,
typically to display the resulting records of a database query.


=head2 attributes

=head3 Abstract

  <tag petal:attributes="attr1 EXPRESSION_1; attr2 EXPRESSION_2"; ...">
     blah blah blah
  </tag>

=head3 Example

  <a href="http://www.gianthard.com"
     lang="en-gb"
     petal:attributes="href document/href_relative; lang document/lang">

=head3 Why?

Attributes statements can be used to replace the values of the attributes
which belong to the tag in which they are used.


=head2 content

=head3 Abstract

  <tag petal:content="EXPRESSION">Dummy Data To Replace With EXPRESSION</tag>

By default, the characters '<', '>', '"' and '&' are encoded to the entities
'&lt', '&gt;', '&quot;' and '&amp;' respectively. If you don't want them to
(because the result of your expression is already encoded) you have to use
the 'structure' keyword.

=head3 Example

  <span petal:content="title">Dummy Title</span>

  <span petal:content="structure some_modifier:some/encoded/variable">
     blah blah blah
  </span>

=head3 Why?

Lets you replace the contents of a tag with whatever value the evaluation of
EXPRESSION returned. This is handy because you can fill your XML/XHTML templates
with dummy content which will make them usable in a WYSIWYG tool.


=head2 replace

=head3 Abstract

  <tag petal:content="EXPRESSION">
    This time the entire tag is replaced
    rather than just the content!
  </tag>

=head3 Example

  <span petal:replace="title">Dummy Title</span>

=head3 Why?

Similar reasons to 'contents'. Note however that 'petal:content' and
'petal:replace' are *NOT* aliases. The former will replace the contents
of the tag, while the latter will replace the whole tag.

Indeed you cannot use petal:content and petal:replace in the same tag.


=head2 omit-tag

=head3 Abstract

  <tag petal:omit-tag="EXPRESSION">Some contents</tag>

=head3 Example

  <b petal:omit-tag="not:bold">I may not be bold.</b>

If 'not:bold' is evaluated as TRUE, then the <b> tag will be omited.
If 'not:bold' is evaluated as FALSE, then the <b> tag will stay in place.

=head3 Why?

omit-tag statements can be used to leave the contents of a tag in place
while omitting the surrounding start and end tags if the expression which
is evaluated is TRUE.


=head2 on-error

=head3 Abstract

  <tag on-error="EXPRESSION">...</tag>

=head3 Example

  <p on-error="string:Cannot access object/method!!">
    $object/method
  </p>

=head3 Why?

When Petal encounters an error, it usually dies with some obscure error
message. The on-error statement lets you trap the error and replace it
with a proper error message.


=head2 Using multiple statements

You can do things like:

  <p petal:define="children document/children"
     petal:condition="children"
     petal:repeat="child children"
     petal:attributes="lang child/lang; xml:lang child/lang"
     petal:content="child/data"
     petal:on-error="string:Ouch!">Some Dummy Content</p>

Given the fact that XML attributes are not ordered, withing the same tag
statements will be executed in the following order: define, condition,
repeat, (attributes, content) or (replace) or (omit-tag, content).


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

=head1 AUTHOR

Copyright 2002 - Jean-Michel Hiver <jhiver@mkdoc.com> 

This module is free software and is distributed under the
same license as Perl itself.
