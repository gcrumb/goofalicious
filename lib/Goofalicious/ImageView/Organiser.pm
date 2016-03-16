package Goofalicious::ImageView::Organiser;

use vars qw($VERSION);
$VERSION = "0.02";

=pod

=head1 NAME

Goofalicious::ImageView::Organiser - Image Menu Maker

=head1 SYNOPSIS

  use Goofalicious::ImageView::Organiser;

  my %args = (
              menu            => [menu_type],
              category        => [category_name],
             );

  my $sizer = Goofalicious::ImageView::Organiser->new(%args);

=head1 DESCRIPTION

The B<Goofalicious::ImageView::Organiser> module displays existing
files on the B<imagicity.com> website in their relevant categories
or creates photo listings based on date or location.

Files are additionally sorted alphabetically by title.

=cut

use strict;
use POSIX;
use Date::Simple (':all');

my $working_dir = '/srv/websites/gallery.imagicity.com';

my %file_index;

my %months = (
              '00'    => 'January',
              '01'    => 'February',
              '02'    => 'March',
              '03'    => 'April',
              '04'    => 'May',
              '05'    => 'June',
              '06'    => 'July',
              '07'    => 'August',
              '08'    => 'September',
              '09'    => 'October',
              '10'    => 'November',
              '11'    => 'December'
             );

sub new {

  my ($class, %args) = @_;
  my $self = {};

  bless $self, $class;

  return $self->init(%args);

}

sub init {

  my ($self, %args) = @_;

# Don't need this yet!
#  return $self unless keys %args;

#  my @required = qw( file max_dimension suffix );

#  while (my ($key, $value) = each %args){
#    $self->{$key} = $value;
#  }

#  foreach (@required){
#    unless (grep($_, keys %args)){
#      warn "Uh-oh missing $_ property\n";
#    }
#  }

  die "Unable to initialise the file listing!\n"
    unless $self->get_nfo_list();

  $self->build_date_listing();

  return $self;

}

sub by_date {

  my $self = shift;

  my $counter = 0;

  my $file_index = $self->{file_index};

  foreach my $this_year (keys %$file_index){

    # Create the monthly lists first, then print them
    my $month_list = $file_index->{$this_year};
    my @month_files = ();

    foreach my $this_month (sort keys %months){

      if (exists $month_list->{$months{$this_month}}){
        my $month_file = "$this_year\-" . $months{$this_month};
        push (@month_files, $month_file);

        open MONTH, "> $working_dir/$month_file"
          or die "Couldn't open file '$working_dir/$month_file':$!\n";

        my $file_list = $month_list->{$months{$this_month}};

        print MONTH $this_year . "\n";

        foreach (@$file_list){
          $_ =~ s!nfo$!jpg!;
          print MONTH $_ . "\n";
          $counter++;
        }

        close MONTH;
      }
    }

    open YEAR, ">$working_dir/$this_year" 
      or die "Couldn't open file '$working_dir/$this_year' for output: $!\n";

    foreach (@month_files){
      print YEAR $_  . "\n";
    }
  }

  return $counter;
}

sub latest {

  my $self = shift;

  my $date = Date::Simple->new(today());

  my $year        = $date->year();
  #my $this_month  = $date->month();
  my $this_month  = $months{sprintf("%02d", $date->month() - 1)};
  my $last_month  = $months{sprintf("%02d", $date->month() - 2)};

  my $files = [];
  my $this_listing = $self->{file_index}->{$year}->{$this_month} || [];
  my $that_lasting = $self->{file_index}->{$year}->{$last_month} || [];
  push @$files, @$this_listing;
  push @$files, @$that_lasting;

  open LATEST, "> $working_dir/latest"
    or die "Couldn't open file '$working_dir/latest' for output:$!\n";

  print LATEST "vanuatu\n";
  print LATEST "recent\n";

  foreach (@$files){
    print LATEST "$_\n";
  }

  close LATEST;

  return scalar @$files;

}

sub recent {

  my $self = shift;

  my $date = Date::Simple->new(today() - 60);

  my $year        = $date->year();
  my $this_month  = $months{sprintf("%02d", $date->month() - 1)};

	my $last_month_number = $date->month() == 1 ? 11 : $date->month() - 2;
  my $last_month  = $months{sprintf("%02d", $last_month_number)};

  my $files = [];
  my $this_listing = $self->{file_index}->{$year}->{$this_month} || [];
  my $that_lasting = $self->{file_index}->{$year}->{$last_month} || [];
  push @$files, @$this_listing;
  push @$files, @$that_lasting;

  open RECENT, "> $working_dir/recent"
    or die "Couldn't open file '$working_dir/recent' for output:$!\n";

  print RECENT "vanuatu\n";
  print RECENT "recent\n";

  foreach (@$files){
    print RECENT "$_\n";;
  }

  close RECENT;

  return scalar @$files;

}

sub get_photo_date {

  my $self     = shift;
  my $nfo_file = shift;

  my ($month, $year);

  return undef unless (defined $nfo_file && $nfo_file);

  unless (-r $nfo_file){

    my $jpg_file = $nfo_file =~ s!nfo$!jpg!;

    return undef unless -f $jpg_file;

    my  ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
         $atime,$mtime,$ctime,$blksize,$blocks)
      = stat($nfo_file);

    my (undef, undef, undef, $mday, $mon, $year, undef) = localtime($ctime);

    $month = strftime("%B", localtime($ctime));
    $year  = strftime("%Y", localtime($ctime));

    return [$month, $year];

  }

  open NFO, $nfo_file
    or die "Couldn't open file $nfo_file' for input: $!\n";

  while (<NFO>){

    chomp;
    if ($_ =~ /\<p\>(\w+)\W+(\d{4})\<\/p\>/){
      $month = $1;
      $year  = $2;
    }
  }

  close NFO;

  return undef unless (
                       (defined $month && $month) &&
                       (defined $year  && $year)
                      );

  return [$month, $year];

}

sub get_nfo_list {

  my $self = shift;

  opendir IMAGICITY, $working_dir
    or die "Couldn't open '$working_dir':$!\n";

  my @nfo_list = grep { /nfo$/ && -f "$working_dir/$_" } readdir(IMAGICITY);

  closedir IMAGICITY;

  $self->{nfo_list} = \@nfo_list;

  return scalar @nfo_list;

}

sub build_date_listing {

  my $self = shift;

  my $list = $self->{nfo_list};
  my $counter;

  foreach my $this_file (@$list){

    my $date = $self->get_photo_date("$working_dir/$this_file");

    unless (defined $date && scalar @$date){
      warn "File '$this_file' can't be parsed! Ignoring...\n";
      next;
    }

    my ($month, $year) = @$date;

    unless (grep /$month/, values %months){
      warn "Invalid month format for file '$this_file': $month\n";
      next;
    }

    unless ($year =~ /^20[0-9]{2}$/ || $year =~ /^19[0-9]{2}$/){
      warn "Invalid year format for file '$this_file': $year\n";
      next;
    }

    my $monthly_file_list = $self->{file_index}->{$year}->{$month} || [];
    push (@$monthly_file_list, $this_file);
    $self->{file_index}->{$year}->{$month} = $monthly_file_list;
    $counter++;
  }

  return $counter;

}


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
