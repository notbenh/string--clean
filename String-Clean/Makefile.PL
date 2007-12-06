use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'String::Clean',
    AUTHOR              => 'ben hengst <notbenh@CPAN.org>',
    VERSION_FROM        => 'lib/String/Clean.pm',
    ABSTRACT_FROM       => 'lib/String/Clean.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Carp::Assert::More' => 0,
        'YAML' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'String-Clean-*' },
);
