package Goofalicious;
use strict;

our $VERSION = 0.15;

#################### subroutine header begin ####################

=head2 sample_function

 Usage     : How to use this function/method
 Purpose   : What it does
 Returns   : What it returns
 Argument  : What it wants to know
 Throws    : Exceptions and other anomolies
 Comment   : This is a sample subroutine header.
           : It is polite to include more pod and fewer comments.

See Also   : 

=cut

#################### subroutine header end ####################


sub new
{
    my ($class, %parameters) = @_;

    my $self = bless ({}, ref ($class) || $class);

    return $self;
}


#################### main pod documentation begin ###################
## Below is the stub of documentation for your module. 
## You better edit it!


=head1 NAME

Goofalicious - Assorted website modules

=head1 SYNOPSIS

  use Goofalicious;


=head1 DESCRIPTION

This is a stub to hold the namespace and version info for the package.

=head1 USAGE

N/A

=head1 BUGS

Yes.

=head1 SUPPORT



=head1 AUTHOR

    Dan McGarry
    CPAN ID: PACLII
    nanana
    dmcgarry@imagicity.com
    http://www.imagicity.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

#################### main pod documentation end ###################


1;
# The preceding line will help the module return a true value

