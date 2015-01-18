package Goofalicious::ImageView::Sizer;

use strict;
use warnings;
use File::Basename;
require Image::Magick::Thumbnail;
use Image::Size;

use vars qw($VERSION);
$VERSION = "0.05";

=pod

=head1 NAME

Goofalicious::ImageView::Sizer - Image Manipulator

=head1 SYNOPSIS

  use Goofalicious::ImageView::Sizer;

  my %args = (
	      file            => "/path/to/file/filename.ext",
	      max_dimension   => 600,
	      suffix          => "size",
	     );
  my $sizer = Goofalicious::ImageView::Sizer->new(%args);

  unless ($sizer->{file_exists}){
    warn "Couldn't create new image\n" unless
      $sizer->create();
  }

=head1 DESCRIPTION

The B<Goofalicious::ImageView::Sizer> module creates new images

It inherits most of its behaviour from L<Image::Magick::Thumbnail>,
a very simple interface to the L<Image::Magick> size manipulation
functions.

=begin testing


=end testing

=head1 Methods

=over 4

=item new

Object constructor. 

B<NOTE:> Best to leave this alone. Subclass the B<init> method
if you want to do customisations.

=begin testing

diag("");
diag("No more tests apply for this package");
diag("");

=end testing

=cut

sub new {

  my ($class, %args) = @_;
  my $self = {};

  bless $self, $class;

  return $self->init(%args);

}

sub init {

  my ($self, %args) = @_;

  return $self unless keys %args;

  my @required = qw( file max_dimension suffix );

  while (my ($key, $value) = each %args){
    $self->{$key} = $value;
  }

  foreach (@required){
    unless (grep($_, keys %args)){
      warn "Uh-oh missing $_ property\n";
    }
  }

  return undef unless -f $self->{file};

  my ($file_name, $path, $suffix) = fileparse($self->{file}, qr{\.jpg});

  if ($self->{suffix} eq "size"){
    $self->{img_name} = $file_name . "_" . $self->{max_dimension}  . $suffix;
  }
  else {
    $self->{img_name} = $file_name . "_" . $self->{suffix} . $suffix;
  }

  $self->{img_path} = $path;

  my $file_to_test = $self->{img_path} . "/" . $self->{img_name};

  if (-f $file_to_test){
    $self->{file_exists} = $self->{img_name};
		# get the image size, and print it out
		my( $width, $height ) = imgsize( $file_to_test );
		$self->{orientation} = 'landscape';
		if (($height && $width) && $height > $width){
			$self->{orientation} = 'portrait';
		}
  }
  else {
    $self->{file_exists} = "";
  }

  return $self;

}

sub orientation {

  my $self = shift;

  return undef unless -r $self->{file};

  my( $width, $height ) = imgsize( $self->{file} );
  $self->{orientation} = 'landscape';
  if ($height > $width){
    $self->{orientation} = 'portrait';
  }

  return $self->{orientation};

}

sub create {

  my $self = shift;
	my $params = shift || {};

	if (scalar keys %$params){
		foreach my $this_setting (keys %$params){
			$self->{$this_setting} = $params->{$this_setting};
		}
	}

	return '' unless $self->{img_path} && $self->{img_name};
  my $new_img_name = $self->{img_path} . "/" . $self->{img_name};
  my $sizer = new Image::Magick;
  $sizer->Read($self->{file});

  my ($thumb,$x,$y) = Image::Magick::Thumbnail::create($sizer, $self->{max_dimension});

	warn "Couldn't write file '$new_img_name'\n" unless defined $thumb;
  $thumb->Write($new_img_name) if defined $thumb;

  return $new_img_name;

}

#sub create {

#	my $self = shift;

#	my $new_img_name = $self->{img_path} . "/" . $self->{img_name};

#	my $image = Image::Resize->new($self->{file});

#	my $width  = $image->width();
#	my $height = $image->height();

#	my $thumbnail = $image->resize($self->{max_dimension}, $self->{max_dimension});

#	open(JPG, ">$new_img_name") or die "Unable to write JPG '$new_img_name': $!";
#	print JPG $thumbnail->jpeg();
#	close(JPG);

#	return $self->{img_name};

#}

1;

__END__

=head1 TODO

=over 4

=item *

Nothing yet. 8^)

=back

=head1 SEE ALSO

=over 4

=item *

L<Image::Magick>

=item *

L<Image::Magick::Thumbnail>

=back

=head1 Author

Dan McGarry L<E<lt>dmcgarry@moodindigo.caE<gt>>

=cut
