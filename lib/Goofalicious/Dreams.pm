package Goofalicious::Dreams;

use strict;
use warnings;

use vars qw( $VERSION );
our $VERSION = '0.01';

use Carp qw( carp croak );

use MLDBM qw(DB_File Storable);	
use Fcntl;

=head1 NAME

Goofalicious::Dreams - Create semi-pseudo-random dream monologues. Everybody wants to!

=head1 SYNOPSIS

  use Goofalicious::Dreams;

  my $dreamer = Goofalicious::Dreams->new ( dream_index => '/foo/dream_index' );

  # Create a new monologue using a random selection...
  my $output_mode = 'plain_text';
  my $monologue = $dreamer->create($output_mode);

  # Or create a new monologue using a selected monologue
  $output_mode = 'html';
  my $selected_monologue = 2; # Or whatever the index number of the monologue is
                              # (more explanation on how to derive the index below).
  $monologue = $dreamer->create($selected_mologue, $output_mode);

  # Or create a monologue based on a custom string
  my $custom_monologue = "Now is the time for all good <person> to come to the party.";
  $monologue = $dreamer->create($custom_monologue, $output_mode);

=head1 DESCRIPTION

I wrote the original code for this many moons ago, in *gack* VB. About 4 months later,
I re-wrote it in Perl as a (very) crude CGI script. It is now being reborn and packaged
in its full glory as a Perl module, destined for use as the back-end to a Mason script.

Visit L<http://www.moodindigo.ca/dreams/> to see how it actually works.

=head1 PUBLIC METHODS

=over 4

=item B<new()>

Class constructor. This method accepts one argument: B<dream_index>, which provides the
path and filename of the Berkeley db file containing the raw data for the applet.

=begin testing

=end testing

=cut

sub new {

  my ($class, %args) = @_;

  my $self = {};

  bless $self, $class;
  return $self->init(%args);

}

=item B<init()>

This method is called via the constructor method by default, but can be
called at any time to override or reset its properties.

B<init> returns a copy of itself, so it can be referenced via assignment:

  my $updated_object = $object->init(%new_args);

or directly to update an existing object:

  $object->init(%new_args);

B<NOTE:> The fact that you have set properties in this method does B<not>
mean that anything will be done with them, necessarily.

=begin testing

diag("");
diag("[No tests for init method]");
diag("");

=end testing

=cut

sub init {

  my ($self, %args) = @_;

  ##################################
  # Dream File index
  $self->{dream_index} = delete $args{dream_index} ||
    $ENV{GOOF_DREAM_FILE} ||
      "/tmp/test_dream_index";

  ##################################
  # Generic and/or custom configuration values.
  while (my ($key, $value) = each %args){
    $self->{$key} = $value;
  }

  my ($monologue_count, $word_count) = $self->_load_index();

  croak "No monologues loaded." unless defined $monologue_count && $monologue_count;
  croak "No words loaded." unless defined $word_count && $word_count;

  return $self;

}

=item B<dream_list()>

Returns an arrayref of all available monologues, each prepped with substitute values.

Optionally, if the B<raw> argument is True, no substitution is performed. If the
optional truncate value is a positive integer, each monologue is truncated to
the specified length.

=begin testing

=end testing

=cut

sub dream_list {

  my ($self, $raw, $truncate) = @_;

  my $monologues = $self->{monologues};
  my @dreams = ();

  carp "No monologues loaded." unless defined $monologues;

  if (defined $truncate && $truncate !~ /\D/){
    foreach my $i (0 .. $#$monologues){
      $dreams[$i] = $self->create($monologues->[$i]);
      $dreams[$i] =~ s/^\s+//;
      $dreams[$i] =~ s/\\//;
      $dreams[$i] = substr($dreams[$i], 0, $truncate) . '...';
    }
  }
  else {
    carp "Value of truncate argument ($truncate) must be numeric."
      if $truncate =~ /\D/;
  }

  unless (defined $raw && $raw){
    foreach my $i (0 .. $#dreams){
      $dreams[$i] = $self->create($dreams[$i]);
    }
  }

  return \@dreams;

}

=item B<create()>

Performs a series of pseudo-random substitutions of tagged data within
a string, replacing each so-identified section with a word or phrase
contained in the appropriate part of the B<words> collection.

This method accepts either an integer or a string. If an integer is passed,
then the string stored at that ordinal position in the B<monologues>
collection is retrieved and processed. If a string is passed, then that
string is processed instead.

Returns the reconstructed string.

=begin testing

=end testing

=cut

sub create {

  my ($self, $monologue, $output_mode) = @_;

  $output_mode = 'html' unless defined $output_mode && $output_mode;

  if (defined $monologue && ($monologue eq 'html' || $monologue eq 'plain_text')){

    $output_mode = $monologue;

    my $monologue_list = $self->{monologues};
    $monologue = $monologue_list->[int(rand($#$monologue_list))];

  }

  unless (defined $monologue){
    my $monologue_list = $self->{monologues};
    $monologue = $monologue_list->[int(rand($#$monologue_list))];
  }

  unless ($monologue =~ /\D/){
    $monologue = $self->{monologues}->[$monologue];
  }

  my @used = ();

  return $self->_process($monologue);

}

=back

=head1 PRIVATE METHODS

=over 4

=item B<_load_index()>

Loads a Berkeley DB index containing all necessary raw data for this applet.
Pushes the raw data into two structures:

=over 4

=item B<monologues>

An arrayref of monologues. Each of these is a string containing the text of
the monologues with the generic word placeholders still in place.

=item B<words>

A hashref of word types. Word types consist of:

  Noun - any noun or moninal phrase that does not fit into the 'Name' category
  Pronoun
  Adjective - any word or phrase that modifies a noun
  Preposition - again, can be a word or a phrase
  Article
  Verb - verbs must be present tense, intransitive and in the form of a gerund (i.e. '...ing')
  Adverb - any word or phrase modifying a verb
  Punctuation - not used
  Expletive - any explosive utterance
  Name - any word or phrase identifying a person, object or entity
  Place
  Number - any word or phrase defining the number of Noun
  Emotion - any word or phrase descriptive of emotional state

Each of the keys listed above contains an arrayref of individual words or phrases.

=back

This method returns an array containing the number of monologues and words successfully
loaded, in that order.

B<Note:> While it is possible to reference this method directly, it is preferable to
load a new index via the B<init()> method instead. This gives me the luxury of rewriting
the B<_load_index> method in the future without affecting the public API.

The B<new_index> argument is designed for internal use only.

=begin testing

=end testing

=cut

sub _load_index {

  my ($self, $new_index) = @_;

  my $index = $new_index || $self->{dream_index}
    or croak "No valid data index";

  croak "Data index '$index' is not readable" unless -r $index;

  my %index;
  tie %index, 'MLDBM', $index, O_RDONLY or croak "Couldn't open index: $!\n";

  my $monologues = [];
  my $words      = {};

  my $monologue_count = 0;
  my $word_count      = 0;

  foreach my $content (keys %index){

    my $meta = $index{$content};

    if ($meta eq 'monologue'){
      push @$monologues, $content;
      $monologue_count++;
    }
    else {
      my $word_list = $words->{$meta} || [];
      push @$word_list, $content;
      $words->{$meta} = $word_list;
      $word_count++;
    }
  }

  $self->{monologues} = $monologues;
  $self->{words}      = $words;

  return ($monologue_count, $word_count);

}

=item B<_process()>

Performs the actual task of substituting randomly selected words of the type
specified in the string passed to this method.

=begin testing

=end testing

=cut

sub _process {

  my ($self, $monologue) = @_;

  my $word_list = $self->{words} or croak "Word data not loaded.";

  my @word_types = keys %$word_list;

  foreach my $word_type (@word_types){

    my $words = $word_list->{$word_type};
    my $random_index;

    #Nouns ride the special bus...
    if ($word_type eq "Noun"){

      while ($monologue =~ /\<plural $word_type\>/i){
	$random_index = int(rand(scalar @$words));
	my $this_word = $words->[$random_index];

	# We should never have to cope with newlines in the middle of a string.
	# $this_word =~ s/\n//;
	chomp $this_word;

	if ($this_word =~ /(us|sh|ch)$/){
	  $this_word .= "es";
	}
	elsif ($this_word =~ /(eep|oose)$/){
	  #Collective noun. Don't change anything.
	}
	else {
	  $this_word .= "s";
	}
	$monologue =~ s/\<plural $word_type\>/$this_word/;
      }
    }

    while ($monologue =~ /\<$word_type\>/i){
      $random_index = int(rand(scalar @$words));
      $monologue =~ s/\<$word_type\>/$words->[$random_index]/;
    }
  }

  return $self->_grammaticise($monologue);

}

=item B<_grammaticise()>

Performs a few small grammar-related housekeeping tasks:

=over 4

=item Changes 'a' to 'an' where appropriate

=item Cleans up whitespace as required

=item Fixes capitalisation where required

=back

=begin testing

=end testing

=cut

sub _grammaticise {

  my ($self, $monologue) = @_;

  # There's probably a better way to parse in grammar rules,
  # but for the time being I'm just going to process the
  # string serially. I know: Yuck!

  carp "No monologue to grammaticise." unless defined $monologue && $monologue;

  my @dream_words = ();
  my $output = "";

  @dream_words = split(/\s/,$monologue);

  # Watch for leading spaces in the file.
  if ($dream_words[0] =~ /^\s$/){
    shift @dream_words;
  }

  foreach my $i (0 .. $#dream_words){

    my $this_word = $dream_words[$i];

    # Clean out leading white space.
    $this_word =~ s/^\s//;

    # Capitalize first letter of Dream (if not capitalized already).
    if ($i == 0){
      $this_word =~ s/(^\w{1})/\u$1/;
    }
    # Use the elsif construct to avoid referencing $dream_words[0 - 1],
    # and capitalize the first word of each sentence.
    elsif ($dream_words[$i - 1] =~ /\.$/){
      $this_word =~ s/(^\w{1})/\u$1/;
    }

    # Match articles to vowel/consonant word starts.
    if ($this_word =~  /a$/ && $dream_words[$i + 1] =~ /^(a|e|i|o|u)/){
      $this_word = "an";
    }

    # Lastly (for now) avoid leading spaces between words and stray punctuation marks
    if ($this_word =~ /^\W/){
      $output .= $this_word;
    }
    else {
      $output .= " $this_word";
    }
  }

  $output =~ s/\,\,/\,/g;
  return $output;

}


1;
__END__

=back

=head1 SEE ALSO

L<http://www.moodindigo.ca/dreams/>

=head1 AUTHOR

Dan McGarry, E<lt>dmcgarry@moodindigo.ca<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 1998, 2003 by Dan McGarry

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
