package TestCase::Spec::Builder;

=head1 NAME

TestCase::Spec::Builder

=head1 DESCRIPTION

Custom Test::Builder object so that TestCase::Spec can automatically inject its test names into TAP output.

See TestCase::Spec for this is used.

=cut

use strict;
use warnings;

use parent qw( Test::Builder );

use TestCase::Spec qw();

sub ok
{
    my ( $self, $test, $name ) = @_;

    my $test_name = $name // TestCase::Spec::test_name();

    return $self->SUPER::ok( $test, $test_name );
}

1;