#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use TestCase::Spec;

plan tests => 1;

my @executed;

describe "describe 1" => sub {
    before 'all'      => sub { push( @executed, "before all 1"  ) };
    before 'each'     => sub { push( @executed, "before each 1" ) };
    after  'each'     => sub { push( @executed, "after each 1"  ) };
    after  'all'      => sub { push( @executed, "after all 1"   ) };
    it     "test 1.1" => sub { push( @executed, "test 1.1"      ) };
    it     "test 1.2" => sub { push( @executed, "test 1.2"      ) };

    describe 'describe 2' => sub {
        before 'all'      => sub { push( @executed, "before all 2"  ) };
        before 'each'     => sub { push( @executed, "before each 2" ) };
        after  'each'     => sub { push( @executed, "after each 2"  ) };
        after  'all'      => sub { push( @executed, "after all 2"   ) };
        it     "test 2.1" => sub { push( @executed, "test 2.1"      ) };
        it     "test 2.2" => sub { push( @executed, "test 2.2"      ) };
    };
};

is_deeply(
    \@executed,
    [
        'before all 1',
            'before each 1',
                'test 1.1',
            'after each 1',

            'before each 1',
                'test 1.2',
            'after each 1',

            'before all 2',
                'before each 1',
                'before each 2',
                    'test 2.1',
                'after each 2',
                'after each 1',

                'before each 1',
                'before each 2',
                    'test 2.2',
                'after each 2',
                'after each 1',
            'after all 2',
        'after all 1',
    ],
    'runs in intended order'
);