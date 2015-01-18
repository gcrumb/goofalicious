package Goofalicious::ImageView;

use strict;
use Apache2::Const qw(:common);
use Apache2::RequestRec;
use	Apache2::RequestIO;
use Apache2::RequestUtil ();
use File::Basename;
use Goofalicious::ImageView::Parser;
use Goofalicious::ImageView::Sizer;
use Data::Dumper;

=pod

=head1 NAME

Goofalicious::ImageView - Primitive web data viewer interface

=head1 SYNOPSIS

  <FilesMatch "*.html">
    SetHandler perlscript
    PerlHandler Goofalicious::ImageView
  </FilesMatch>
  <FilesMatch "*.jpg">
    SetHandler perlscript
    PerlHandler Goofalicious::ImageView
  </FilesMatch>

=head1 DESCRIPTION

The B<Goofalicious::ImageView> module provides a simple, but 
feature-free way of viewing the images stored in the /imagicity/ 
section on goofalicious.com

It is designed solely for use via mod_perl.

That is all.

=begin testing

use_ok('Goofalicious::ImageView');
$test_db = new Goofalicious::ImageView;
isa_ok($test_db, 'Goofalicious::ImageView');

=end testing

=head1 Methods

=over 4

=item new

Object constructor. Called once for every child process instantiated
by apache.

=begin testing

diag("");
diag("No more tests apply for this package");
diag("");

=end testing

=cut

#sub new {

#  my $class = shift;
#  my $self = {};

#  bless $self, $class;

#  return $self;

#}

# Default callback function
sub handler {

  my $r = shift;
  my $file_writer = new Goofalicious::ImageView::Parser;
  my $file = $r->filename;

	if ($file =~ /.jpg$/i){
		unless (-f $file){

			if ($file =~ /_(\d+)/){

				my $dir    = '/srv/websites/gallery.imagicity.com';
				my $size   = $1;
				my $source = $file;

				$source =~ s!_\d+\.jpg!.jpg!i;

				my $img_attrs = {
												 file            => $source,
												 max_dimension   => $size,
												 suffix          => "size",
												};

				my $sizer = new Goofalicious::ImageView::Sizer;
				$sizer->init(%$img_attrs);
				my $result = $sizer->create();

				$r->sendfile($file);
				return OK;

			}
		}
	}

  return DECLINED unless $r->content_type() eq 'text/html';

  # Gather up any GET data being passed.
  my %params;
  my $query_string = $r->args;

  foreach my $pair (split(/\&/, $query_string)){

    my ($key, $value) = split(/\=/, $pair);
    $params{$key} = $value;

  }
  # Decode any URLEncoded data
  while (my ($key, $value) = each %params){
    $params{$key} = URLDecode($value);
  }

  # We need the path to know which dir to read for the
  # menu to be generated.
  $params{path} = dirname($r->filename);

  # ... and pass it straight on to the table writer.
  $file_writer->{parse_params} = \%params;

  my $p = $file_writer->parse_file($file);

  # Print the parsed document...
  print '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"'
    . '"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">';
  print $p->{full_text};

  # All done.
  return OK;
}

sub clean_vars {

  #my $self = shift;

  # This is a noop for now....
  return 1;

}

#Decode a given string that came from a URL/URI
sub URLDecode {

  my $input_string = shift;

  $input_string =~ s/%([\da-fA-F]{1,2})/sprintf("%c", hex($1))/eg;
  $input_string =~ s/\+/ /g;

  return $input_string;

}


1;

__END__

=back

=head1 TODO

=over 4

=item *

Provide more sophisticated data selection interface.

=back

=head1 SEE ALSO

=over 4

=item *

L<PageReports::DB>

=item *

L<PageReports::DB::TableWrite>

=back

And the online documentation at:

L<http://geek.moodindigo.ca/pagereports/>


=head1 Author

Dan McGarry, for Marigold Technologies

=cut

