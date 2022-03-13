use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
        FIRST_MAKEFILE  => 'Makefile.xs',
        NAME            => 'Lossless',
        VERSION_FROM    => 'lib/Lossless.pm',
        PREREQ_PM       => {},
        INC             => '-I..',
        MYEXTLIB        => 'liblossless.so',
        AUTHOR          => 'Matthew King',
        LICENSE         => 'perl',
);
