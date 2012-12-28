

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
							NAME         => 'Goofalicious',
							VERSION_FROM => 'lib/Goofalicious.pm', # finds \$VERSION
							AUTHOR       => 'Dan McGarry (dmcgarry@imagicity.com)',
							ABSTRACT     => 'Assorted website modules',
							PREREQ_PM    => {
															 'Test::Simple'        => 0.44,
															 'Carp'                => 0,
															 'HTML::Parser'        => 0,
															 'POSIX'               => 0,
															 'Date::Simple'        => 0,
															 'File::Basename'      => 0,
															 'Apache2::Const'      => 0,
															 'Apache2::RequestRec' => 0,
															 'Apache2::RequestUtil' => 0,
															},
							EXE_FILES => [qw(
																bin/add-thumbnail-to-summaries.pl
																bin/random-photos
																bin/noback
																bin/prep-templates	
                             )],

);
