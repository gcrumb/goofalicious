#!/usr/bin/perl -w

eval 'exec /usr/bin/perl -w -S $0 ${1+"$@"}'
    if 0; # not running under some shell

use strict;

use DBD::mysql;
use DBI;

my $db         = 'wordpress';
my $db_host    = 'localhost';
my $db_user     = 'wp-sysadmin';
my $db_pass    = 'd7b7bf46076914ec03dbdcae42cdedb0';

my $db_handle = DBI->connect ("DBI:mysql:database=$db:host=$db_host",
			      $db_user,
			      $db_pass) 
  or die "Can't connect to database: $DBI::errstr\n";

my $query = qq/
          select ID, post_content, post_excerpt
          from wp_posts
          /;

my $sth = $db_handle->prepare($query);

$sth->execute() or die "Query didn't work\n";

while ( my $this_row = $sth->fetchrow_hashref( ) )  {
 
  my $content = $this_row->{post_content};

  next unless $content =~ m!(<img src\=\"http\://gallery\.imagicity\.com/.*?.jpg\" alt\=\".*?\" /\>)!;

  my $excerpt = $1;
  $excerpt =~ s/[0-9]+\.jpg/300\.jpg/;

  #print $excerpt . "\n";

  my $update_sql = qq/
                     UPDATE wp_posts
                     SET post_excerpt = ?
                     WHERE ID = ?
                     /;

  my $update_handle = $db_handle->prepare($update_sql);
  $update_handle->execute($excerpt, $this_row->{ID});

}

$db_handle->disconnect;
print "All Done.\n";

