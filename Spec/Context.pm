package TestCase::Spec::Context;

=head1 NAME

TestCase::Spec::Context

=head1 DESCRIPTION

An object to represent the running context of tests in TestCase::Spec.
This exists to provide compatibility with Test::Spec::Context in Test::Spec (https://metacpan.org/pod/Test::Spec).

=cut

use strict;
use warnings;

sub new
{
    my ( $class, %context ) = @_;

    return bless( { %context }, $class );
}

sub description { my $self = shift; return $self->{ description } // 'UNKNOWN' }

1;