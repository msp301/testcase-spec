#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

my $repo      = 'github.com/msp301/testcase-spec';
my $repo_http = "https://$repo";

WriteMakefile(
    AUTHOR       => 'Martin Pritchard <martin@martinpritchard.com>',
    LICENSE      => 'artistic_2',
    META_MERGE   => {
        'meta-spec' => { version => 2 },
        resources => {
            bugtracker  => {
                web => "$repo_http/issues",
            },
            homepage    => $repo_http,
            respository => {
                type => 'git',
                url  => "git://$repo.git",
                web  => $repo_http,
            },
        },
    },
    NAME         => 'TestCase::Spec',
    PREREQ_PM    => {
        'Carp'             => 0,
        'Exporter'         => 0,
        'List::Util'       => 1.33,
        'Test::MockModule' => 0.13,
        'Test::More'       => 0,
        'Try::Tiny'        => 0,
    },
    VERSION_FROM => 'lib/TestCase/Spec.pm',
);