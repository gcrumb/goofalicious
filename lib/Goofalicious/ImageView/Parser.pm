##################### START HTML PARSER ##################################
# This wrapper performs the actual task of finding valid places to run the
# insertion.

package Goofalicious::ImageView::Parser;
use base HTML::Parser;
use Goofalicious::ImageView::Sizer;

use strict;

=pod

=head1 NAME

Goofalicious::ImageView::Parser - Primitive image viewer interface

=head1 SYNOPSIS

  use Goofalicious::ImageView::Parser;

  my $parser = new Goofalicious::ImageView::Parser;
  my $file_to_parse = "/foo/bar/baz.html";

  my @cols = qw (contact_id first_name last_name title contact_page_url);

  my %params = (style_sheet     => "/mystyle.css",
		table           => "contact",
		cols            => \@cols);

  my $p = $table_writer->parse_file($file);
  print $p->output;

=head1 DESCRIPTION

The B<Goofalicious::ImageView::Parser> module reads an HTML template
and parses it, replacing:

=over 4

=item Empty HEAD with Custom stylesheet

=item Data-populated table for generic place-holder.

=back

It inherits its behaviour from L<HTML::Filter>, an old but simple
child of L<HTML::Parser>.

=begin testing


=end testing

=head1 Methods

=over 4

=item new

Object constructor. A new B<Goofalicious::ImageView::Parser>
object is created every time the template file is read.

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

sub start{

  my ($self, $tag, $attr, $attrseq, $origtext) = @_;

  $self->{head} = 1 if $tag =~ /head/i;
  $self->{getHeading} = 1 if $tag =~ /h2/i;
  if ($tag =~ /meta/i){
    $self->{meta} = 1;
    return;
  }
  if ($tag =~ /imageholder/){
    $self->{image} = 1;
    return;
  }
  if ($tag =~ /menu/i){
    $self->{menu} = 1;
    return;
  }
  $self->SUPER::start(@_);

  $self->{full_text} .= $origtext;
}

sub end {

  # Turn off parse flags when necessary.
  my ($self, $tag, $origtext) = @_;

  $self->{head}       = 0 if $tag =~ /head/i;
  $self->{getHeading} = 0 if $tag =~ /h2/i;
  $self->{meta}       = 0 if $tag =~ /meta/i;
  $self->{image}      = 0 if $tag =~ /imageholder/i;
  $self->{menu}       = 0 if $tag =~ /menu/i;

  $self->SUPER::end(@_);

  $self->{full_text} .= $origtext;
}


# This is where the actual substitution work gets done.
sub text {

  my ($self, $chunk, $remainder) = @_;

  my $comment_start = qr/<!--/;
  my $comment_end = qr/-->/;
	my $img;

	if (
			exists $self->{parse_params}->{pic}
			&& defined $self->{parse_params}->{pic})
		{
			$self->{parse_params}->{img} = $self->{parse_params}->{pic};
		}

  if ($self->{image}){
    my $base_url = "http://gallery.imagicity.com";

    my $img_tag = "";

    if ($self->{parse_params}->{img_size}){

      my $dir = $self->{parse_params}->{path};

      $img = $self->{parse_params}->{img};

      my %attrs = (
		   file            => "$dir/$img",
		   max_dimension   => $self->{parse_params}->{img_size},
		   suffix          => "size",
		  );

      my $sizer = Goofalicious::ImageView::Sizer->new(%attrs);
      my $img_file = $sizer->{file_exists} || $sizer->create();

      $img_tag = "<img src='$base_url/$img_file' border='0'>\n";

    }
    else {
      $img_tag = "<img src='$base_url/" . $self->{parse_params}->{img} ."' border='0'>\n";
    }

    $img_tag = "" unless $img;
    $chunk =~ s/image_goes_here/$img_tag/;

  }

  if ($self->{menu}){
    my $menu = $self->{parse_params}->{slide_show}
			? $self->make_slideshow() : $self->get_menu();
    $chunk =~ s/menu_goes_here/$menu/;
  }

  if ($self->{meta}){

    my $meta_string = $self->get_meta();
    $chunk =~ s/meta_goes_here/$meta_string/;

  }

  $self->{full_text} .= $chunk;

}

sub get_menu {

  my $self = shift;

  my %sizes = ('0700'     => "small",
							 '0900'     => "medium",
							 '1200'     => "large",);

  my $output;
  my @img_list = ();
  my @category_list = ();

  my $base_url = $self->{parse_params}->{base_url}
    || "http://gallery.imagicity.com";

  if  ($self->{parse_params}->{img}){
    $output = "<p><a href='http://www.imagicity.com/'>Home</a></p>";
    return $output;
  }

  my $sizer = new Goofalicious::ImageView::Sizer;

  if ($self->{parse_params}->{path} && -d $self->{parse_params}->{path}){

    my $dir = $self->{parse_params}->{path};

    if ($self->{parse_params}->{category}){

      my $category_file = $self->{parse_params}->{category};

      if (-r "$dir/$category_file"){

				$output = "<p class='title'>$category_file\n";
				open CATEGORY, "$dir/$category_file" or
					die "Couldn't access category '$category_file: $!\n";

				# Updated to allow category files to contain sub-categories
				while (<CATEGORY>){
					my $entry = $_;
					chomp $entry;
					
					if ($entry !~ /jpg$/i && -f "$dir/$entry"){
						push @category_list, $entry;
					}
					else {
						push @img_list, $entry;
					}
				}
				close CATEGORY;
      }
    }
    else {

      $output = "<p>Available images:<br>\n";
      opendir IMG_DIR, $dir or die "Couldn't read dir '$dir': $!\n";
      my @tmp_list = grep { /nfo$/i && -f "$dir/$_" } readdir IMG_DIR;
      closedir IMG_DIR;

      # Make sure we don't have any orphaned nfo files
      # hanging about
      foreach (@tmp_list){
        my $test_name = $_;
        $test_name = s/nfo$/jpg/;
        push (@img_list, $_) unless -f "$dir/$test_name";
      }

    }

    # Output a menu of sub-categories.
    if (scalar @category_list){
      my $menu_list = "<p class='also'>See also: |";
      my $category;
      foreach $category (sort @category_list){
        my $display = $category;
        $display =~ s!^\d{4}\-(\w+)$!$1!;
        $menu_list .= "| <a href='$base_url/imageview.html?category=$category'>$display</a> |";
      }

      $category = $self->{parse_params}->{category};
      $menu_list .= "|";
      $menu_list .= "\&nbsp;\&nbsp; ";
      $menu_list .= "<strong><a href='$base_url/imageview.html?category=$category&slide_show=1'>";
      $menu_list .= "view slideshow</a></strong></p>";

      $output .= $menu_list;
    }

    # Sort by description, not by filename
    my %img_list = ();

    foreach my $img (@img_list){

      $img =~ s/nfo$/jpg/ if $img =~ /nfo$/;
      $img_list{$self->get_img_desc($dir, $img)} = $img;

    }

    foreach my $img_desc (sort keys %img_list){

      my $img = $img_list{$img_desc};
      next unless $img;

			my @thumb_sizes = (200,400,300,500);
			my $random_size = $thumb_sizes[int(rand(scalar(@thumb_sizes)))];

      my %attrs = (
		   file            => "$dir/$img",
		   max_dimension   => $random_size,
		   suffix          => "size",
		  );

      $sizer->init(%attrs);

      my $thumbnail = $sizer->{file_exists};
      $thumbnail = $sizer->create() unless $thumbnail;
      my $link = "<a href='$base_url/$img'>";
      my $link_img = "<img src='$base_url/$thumbnail' border='0'>";
      $output .= "\t<div class='item item$random_size'>$link$link_img</a>\n";

      $output .= "<span class='item-desc'>$link$img_desc</a><br />View: \n";
      foreach my $size (sort keys %sizes){
        my $desc = $sizes{$size};
        $size =~ s!^0!!;
        $link = "<a href='$base_url/imageview.html?img=$img&img_size=$size'>";
        $output .= "$link$desc</a>&nbsp;";
      }
      $output .= "</span></div>";
    }
  }

  return $output;

}

sub get_img_desc {

  my ($self, $dir, $img) = @_;

  my $img_desc = "";
  my $img_desc_file = "";

  my $img_file = "$dir/$img";
  return undef unless (defined $img_file && -r $img_file);

  ($img_desc_file = $img_file) =~ s/jpg$/nfo/i;

  return $img unless -r $img_desc_file;

  open IN, $img_desc_file or die "Couldn't open file '$img_desc_file': $!\n";

  while (<IN>){
    if (/^<p class='name'>(.*?)<\/p>/i){
      close IN;
      return $1;
    }
  }

  close IN;
  return $img;

}

sub get_meta {

  my $self = shift;
  my $img_desc_file = "";
  my $output = "";

  return undef unless exists $self->{parse_params}->{img};

  my $img = $self->{parse_params}->{path} . "/" . $self->{parse_params}->{img};

  ($img_desc_file = $img) =~ s/jpg$/nfo/i;

  return "" unless -r $img_desc_file;

  open IN, $img_desc_file or die "Couldn't open file '$img_desc_file': $!\n";

  my ($tag, $content);
  while (<IN>){
    $content .= $_;
  }
  close IN;

  return $content;

}

sub make_slideshow {

	my $self = shift;

  my %sizes = ('0700'     => "small",
              '0900'     => "medium",
              '1200'     => "large",);

  my $output;
  my @img_list = ();
  my @category_list = ();

  my $base_url = $self->{parse_params}->{base_url}
    || "http://gallery.imagicity.com";

  if  ($self->{parse_params}->{img}){
    $output = "<p><a href='http://www.imagicity.com/'>Home</a></p>";
    return $output;
  }

  my $sizer = new Goofalicious::ImageView::Sizer;

  if ($self->{parse_params}->{path} && -d $self->{parse_params}->{path}){

    my $dir = $self->{parse_params}->{path};

    if ($self->{parse_params}->{category}){

      my $category_file = $self->{parse_params}->{category};

      if (-r "$dir/$category_file"){

				open CATEGORY, "$dir/$category_file" or
					die "Couldn't access category '$category_file: $!\n";

				# Updated to allow category files to contain sub-categories
				while (<CATEGORY>){
					my $entry = $_;
					chomp $entry;
					
					if ($entry !~ /jpg$/i && -f "$dir/$entry"){
						push @category_list, $entry;
					}
					else {
						push @img_list, $entry;
					}
				}
				close CATEGORY;
      }
    }
    else {

      $output = "<p>Available images:<br>\n";
      opendir IMG_DIR, $dir or die "Couldn't read dir '$dir': $!\n";
      my @tmp_list = grep { /nfo$/i && -f "$dir/$_" } readdir IMG_DIR;
      closedir IMG_DIR;

      # Make sure we don't have any orphaned nfo files
      # hanging about
      foreach (@tmp_list){
        my $test_name = $_;
        $test_name = s/nfo$/jpg/;
        push (@img_list, $_) unless -f "$dir/$test_name";
      }

    }

    # Output a menu of sub-categories.
    if (scalar @category_list){
      my $menu_list = "<p class='also'>See also: |";
      foreach my $category (sort @category_list){
        my $display = $category;
        $display =~ s!^\d{4}\-(\w+)$!$1!;
        $menu_list .= "| <a href='$base_url/imageview.html?category=$category'>$display</a> |";
      }
      $menu_list .= "|</p>";

      $output .= $menu_list;
    }

    # Sort by description, not by filename
    my %img_list = ();

    foreach my $img (@img_list){

      $img =~ s/nfo$/jpg/ if $img =~ /nfo$/;
      $img_list{$self->get_img_desc($dir, $img)} = $img;

    }

		$output   .= "\n<div id='slideshow'>\n";
		$output   .= "\n\t<div id='next'><a href='#'>&raquo;</a></div>\n";
		my $img_id = 0;
    my $first  = " class='active'";

    foreach my $img_desc (sort keys %img_list){

      my $img     = $img_list{$img_desc};

      next unless $img;
			$img_id++;

      my %attrs = (
		   file            => "$dir/$img",
		   max_dimension   => 700,
		   suffix          => "size",
		  );

      $sizer->init(%attrs);
		
			if ($sizer->orientation() eq 'portrait'){
				$attrs{max_dimension} = 465;
				$sizer->init(%attrs);
			}

			$img_desc     =~ s!\'!\&apos\;!g;
			$img_desc     =~ s!\"!\&quot\;!g;

      my $thumbnail = $sizer->{file_exists};
      $thumbnail    = $sizer->create() unless $thumbnail;

      my $div       = "<div$first>";
      my $link      = "<a href='$base_url/$img'>";
      my $caption   = "<div class='caption'>\n\t\t\t$link$img_desc</a>\n\t\t\t</div>";
      my $link_img  = "<img src='$base_url/$thumbnail' border='0' alt='$img_desc' title='View Image' />";

      $output      .= "\t$div\n\t\t$link$link_img</a>\n\t\t$caption</div>\n";
      $first        = '';

    }

		$output .= "</div>";

  }

  return $output;
}

1;

__END__

=back

=head1 TODO

=over 4

=item *

Get it right

=back

=head1 SEE ALSO

=over 4


=item *

L<http://www.goofalicious.com/>

=back

=head1 Author

Dan McGarry, for fun

=cut