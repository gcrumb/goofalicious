

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Goofalicious',
    VERSION_FROM => 'lib/Goofalicious.pm', # finds \$VERSION
    AUTHOR       => 'Graham Crumb (gcrumb@gmail.com)',
    ABSTRACT     => 'Image management utility',
    PREREQ_PM    => {
                     'Test::Simple'         => 0.44,
										 'DBD::mysql'           => 0.0,
										 'DBI'                  => 0.0,
										 'MLDBM'                => 0.0,	
										 'Image::ExifTool'      => 0.0,
										 'Fcntl'                => 0.0,
										 'Getopt::Std'          => 0.0,
										 'Getopt::Long'         => 0.0,
										 'POSIX'                => 0.0,
										 'Date::Simple'         => 0.0,
										 'HTML::Parser'         => 0.0,
										 'File::Basename'       => 0.0,
										 'Image::Size'          => 0.0,
										 'Apache2::Const'       => 0.0,
										 'Apache2::RequestRec'  => 0.0,
										 'Apache2::RequestUtil' => 0.0,
										 'File::Basename'       => 0.0,
										 'File::Slurp'          => 0.0,
										 'HTML::Entities'       => 0.0,
                    },
		 EXE_FILES  => [
										'bin/add-thumbnail-to-summaries.pl',
										'bin/imgsize',
										'bin/noback',
										'bin/prep-templates',
										'bin/random-photos',
									 ],
);
