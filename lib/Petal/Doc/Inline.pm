package Petal::Doc::Inline;
use strict;
use warnings;


1;


__END__


=head1 NAME

Petal::Doc::Inline - Petal Inline Syntax


=head1 SYNOPSIS

This is an article, not a module.


=head1 SUMMARY

This syntax is provided to do simple variable interpolation.

It is quite similar to HTML::Template or the Template Toolkit
syntaxes and it is quite easy to turn into Perl code.


=head1 NAMESPACE

None.


=head1 STATEMENTS

=head2 Syntax

$EXPRESSION - or - ${EXPRESSION}.

If ${EXPRESSION} is followed by a space and if EXPRESSION
itself has no spaces, then the curly brackets are not needed
(although it doesn't hurt to have them).

Otherwise, you need to use ${EXPRESSION}.

In doubt, use ${EXPRESSION}.

To know what EXPRESSION means, see L<Petal::Syntax::Petales>.


=head2 Example

  <p>
    Dear ${user/gender}. ${user/last_name},<br /><br />

    Your current account balance is ${user/account/balance}.
    Your saving account is ${user/savings/amount}.

    That's a total of
    ${math/add user/account/balance user/saving/amount}.

    Just to let you know.
  </p>


=head2 Advice

Don't use this syntax too much except for very simple cases
and rapid prototyping. Use the L<Petal::Syntax::TAL> or the
L<Petal::Syntax::PIs> syntaxes instead.


=head1 AUTHOR

Copyright 2002 - Jean-Michel Hiver <jhiver@mkdoc.com> 

This module is free software and is distributed under the
same license as Perl itself.
