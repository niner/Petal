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


sub process
{
    my $class = shift;
    my $self = shift;
    my $argument = shift;
    
    my @split = split /\s+/, $argument;
    my $path = shift (@split) or confess "bad syntax for $class: $argument (\$path)";
    my $args = join ' ', @split;
    
    my @path = split /\./, $path;
    @path = ($path) unless (@path);
    my @args = ();
    @args = split /\s+/, $args
	if (defined $args and $args);
    
    # replace variable names by their value
    for (my $i=0; $i < @args; $i++)
    {
	my $arg = $args[$i];
	if ($arg =~ /^\$/)
	{
	    $arg =~ s/^\$//;
	    $args[$i] = $class->process ($self, $arg);
	}
    }
    
    my $current = $self;
    while (@path)
    {
	my $next = shift (@path);
	
	if (ref $current eq 'HASH' or ref $current eq 'Petal::Hash')
	{
	    confess "Cannot access hash with parameters"
	        if (scalar @args);
	    
	    $current = $current->{$next};
	}
	
	# it might be an array, then the key has to be numerical...
	elsif (ref $current eq 'ARRAY')
	{
	    confess "Cannot access array with non decimal key"
	        unless ($next =~ /^\d+$/);
	    
	    confess "Cannot access array with parameters"
	        if (scalar @args);
	    
	    $current = $current->[$next];
	}
	
	# ... or maybe an object? ...
	elsif (ref $current)
	{
	    if (scalar @path == 0 and scalar @args > 0)
	    {
		confess "Cannot invoke $next on $argument"
		    unless ($current->can ($next));
		
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
			confess "Cannot access array with non decimal key"
			    unless ($next =~ /^\d+$/);
			$current = $current->[$next];
		    }
		    else
		    {
			confess "Cannot invoke $next on current object";		
		    }
		}
	    }
	}
	
	# ... or we cannot find the next value
	# let's croak and return
	else
	{
	    my $warnstr = "Cannot find value for $path: $next cannot be retrieved\n";
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
    
    return $current;
}


1;










