package TestCase::Spec;

=head1 NAME

TestCase::Spec

=head1 DESCRIPTION

This module is intended to provide some syntactic sugar for writing unit tests
using RSpec style notation.

The API is intended to closely follow the Perl BDD framework Test::Spec whilst
providing compatibility to use TestCase::Spec with other test frameworks
e.g Test::Class.

=head1 EXAMPLE USAGE

    use TestCase::Spec;

    describe 'A kitten' => sub {
        my $kitten = Kitten->new();

        describe 'when stroked' => sub {
            it 'meows' => sub {
                is( $kitten->stroke(), 'meow', TestCase::Spec::test_name );
            };
        };
    };

    # Generates the output:
    # ok 1 - A kitten when stroked meows
    # 1..1

=cut

use Exporter qw( import );
use Test::More;
use Try::Tiny;

our @EXPORT = qw(
    describe
    it
    xit
);

our $CONTEXT = '';

sub test_name
{
    return $CONTEXT;
}

sub describe
{
    my ( $context, $callback ) = @_;

    local $CONTEXT = _extend_context( $context );

    $callback->();

    return;
}

sub it
{
    my ( $context, $callback ) = @_;

    local $CONTEXT = _extend_context( $context );

    if( defined $callback )
    {
        try
        {
            $callback->();
        }
        catch
        {
            my $error = $_;
            fail( "Test died ($CONTEXT) -- $error" );
        };
    }
    else
    {
        local $TODO = '(unimplemented)';
        ok( 1, $CONTEXT );
    }

    return;
}

sub xit
{
    my ( $context, $callback ) = @_;

    local $CONTEXT = _extend_context( $context );

    local $TODO = "(disabled)";
    ok( 0, $CONTEXT );

    return;
}

sub _extend_context
{
    my ( $context ) = @_;

    my $current_context = $CONTEXT;
    $current_context .= ' ' if $current_context;

    return $current_context . $context;

}

1;
