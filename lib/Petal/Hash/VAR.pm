=head1 NAME

Petal::Hash::VAR - THE standard hash modifier, evaluates an expression
and returns the result.

=head1 SYNOPSIS

  $hash->{my_number} = 2;
  my $value = $hash->{'object.method string $my_number'}

=head1 AUTHOR

Jean-Michel Hiver <jhiver@mkdoc.com>

This module is redistributed under the same license as Perl itself.

=head1 SEE ALSO

The template hash module:

  Petal::Hash

=cut
package Petal::Hash::VAR;
use strict;
use warnings;
use Carp;


our $STRING_RE_DOUBLE = qq |(?<!\\\\)\\".*?(?<!\\\\)\\"|;
our $STRING_RE_SINGLE = qq |(?<!\\\\)\\'.*?(?<!\\\\)\\'|;
our $STRING_RE        = "(?:$STRING_RE_SINGLE|$STRING_RE_DOUBLE)";
our $VARIABLE_RE      = "[A-Za-z\_][A-Za-z0-9\_\\.:\/]+";
our $TOKEN_RE         = "(?:$STRING_RE|$VARIABLE_RE)";



sub process
{
    my $class = shift;
    my $hash  = shift;
    my $argument = shift;
   
    my @tokens = $argument =~ /($TOKEN_RE)/gsm;
    my $path   = shift (@tokens) or confess "bad syntax for $class: $argument (\$path)";
    my @path = split /\/|\./, $path;    
    my @args = @tokens;

    # replace variable names by their value
    for (my $i=0; $i < @args; $i++)
    {
	my $arg = $args[$i];
	if ($arg =~ /^$VARIABLE_RE$/)
	{
	    $arg =~ s/\\(.)/$1/gsm;
	    $args[$i] = $hash->FETCH ($arg);
	}
	else
	{
	    $arg =~ s/^(\"|\')//;
	    $arg =~ s/(\"|\')$//;
	    $arg =~ s/\\(.)/$1/gsm;
	    $args[$i] = $arg;
	}
    }
    
    my $current = $hash;
    while (@path)
    {
	my $next = shift (@path);
	if (ref $current eq 'HASH' or ref $current eq 'Petal::Hash')
	{
	    confess "Cannot access $argument"
	        if (scalar @args and not scalar @path);
	    
	    $current = $current->{$next};
	}
	
	# it might be an array, then the key has to be numerical...
	elsif (ref $current eq 'ARRAY')
	{
	    confess "Cannot access array with non decimal key ($argument)"
	        unless ($next =~ /^\d+$/);
	    
	    confess "Cannot access array with parameters ($argument)"
	        if (scalar @args and not scalar @path);
	    
	    $current = $current->[$next];
	}
	
	# ... or maybe an object? ...
	elsif (ref $current)
	{
	    if (scalar @path == 0 and scalar @args > 0)
	    {
		confess "Cannot invoke $next on $argument"
		    unless ($current->can ($next) or $current->can ('AUTOLOAD'));
		
		$current = $current->$next (@args);
	    }

	    else
	    {
		if ($current->can ($next))
		{
		    $current = $current->$next (@args);
		}
		else
		{		    
		    confess "Cannot invoke $next on $argument with @path (not a method)"
			if (@path == 0 and scalar @args > 0);
		    
		    if ($current =~ /=HASH\(/)
		    {
			$current =  $current->{$next};
		    }
		    elsif ($current =~ /=ARRAY\(/)
		    {
			confess "Cannot access array with non decimal key ($argument)"
			    unless ($next =~ /^\d+$/);
			$current = $current->[$next];
		    }
		    else
		    {
			confess "Cannot invoke $next on current object ($argument)";		
		    }
		}
	    }
	}
	
	# ... or we cannot find the next value
	# let's croak and return
	else
	{
	    my $warnstr = "Cannot find value for $argument: $next cannot be retrieved\n";
	    $warnstr .= "(current value was ";
	    $warnstr .= (defined $current) ? "'$current'" : 'undef';
	    $warnstr .= ")";
	    confess $warnstr;
	}
    }
    
    if (defined $current and ref $current eq 'HASH')
    {
	my %current = ();
	tie %current, 'Petal::Hash';
	%current = %{$current};
	$current = \%current;
    }
    
    return '' unless (defined $current);
    return $current;
}


1;










