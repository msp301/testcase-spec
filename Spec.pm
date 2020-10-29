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
        my $kitten;

        before 'each' => sub {
            $kitten = Kitten->new();
        };

        describe 'when stroked' => sub {
            it 'meows' => sub {
                is( $kitten->stroke(), 'meow', TestCase::Spec::test_name );
            };
        };
    };

    # Generates the output:
    # ok 1 - A kitten when stroked meows
    # 1..1

=head1 CAVEATS

To simplify the design of this module, some variations in behaviour from Test::Spec have been taken:

* 'before/after all' will be executed IMMEDIATELY. This means:
** 'before all' routines MUST be added at the beginning of a 'describe'
** 'after all' routines MUST be placed at the end of a 'describe'

=cut

use strict;
use warnings;

use Carp qw( croak );
use Exporter qw( import );
use List::Util qw( any );
use Test::More;
use Try::Tiny;

use TestCase::Spec::Context;

our @EXPORT = qw(
    after
    before
    describe
    it
    xit
);

our $AFTER_EACH  = [];
our $BEFORE_EACH = [];
our $CONTEXT     = '';

sub test_name
{
    return $CONTEXT;
}

sub after
{
    my ( $when, $callback ) = @_;

    my $error = _before_or_after( 'after', $when, $callback );
    croak $error if $error;

    return;
}

sub before
{
    my ( $when, $callback ) = @_;

    my $error = _before_or_after( 'before', $when, $callback );
    croak $error if $error;

    return;
}

sub describe
{
    my ( $context, $callback ) = @_;

    croak "context not provided"                           unless( defined $context and $context ne '' );
    croak "expected subroutine reference as last argument" unless( ref $callback eq 'CODE' );

    local $BEFORE_EACH = $BEFORE_EACH;
    local $AFTER_EACH  = $AFTER_EACH;
    local $CONTEXT = _extend_context( $context );

    $callback->();

    return;
}

sub it
{
    my ( $context, $callback ) = @_;

    local $CONTEXT = _extend_context( $context );

    my $filtered = ( $ENV{ SPEC_FILTER } and index( $CONTEXT, $ENV{ SPEC_FILTER } ) == -1 );

    if( $filtered )
    {
        local $TODO = '(filtered)';
        ok( 1, $CONTEXT );
    }
    elsif( defined $callback )
    {
        try
        {
            _run_before_stack( $BEFORE_EACH );

            $callback->( TestCase::Spec::Context->new( description => "$CONTEXT" ) );

            _run_after_stack( $AFTER_EACH );
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

sub _before_or_after
{
    my ( $type, $when, $callback ) = @_;

    return "$type must be for either 'each' or 'all'"       unless( defined $when and any { $when eq $_ } qw( each all ) );
    return "expected subroutine reference as last argument" unless( ref $callback eq 'CODE' );

    if( $when eq 'each' )
    {
        if( $type eq 'before' )
        {
            $BEFORE_EACH = _extend_before_each( $callback );
        }
        else
        {
            $AFTER_EACH = _extend_after_each( $callback );
        }
    }
    else
    {
        $callback->();
    }

    return;
}

sub _extend_after_each
{
    my ( $callback ) = @_;

    return _extend_stack( $AFTER_EACH, $callback );
}

sub _extend_before_each
{
    my ( $callback ) = @_;

    return _extend_stack( $BEFORE_EACH, $callback );
}

sub _extend_context
{
    my ( $context ) = @_;

    my $current_context = $CONTEXT;
    $current_context .= ' ' if $current_context;

    return $current_context . $context;

}

sub _extend_stack
{
    my ( $stack, $callback ) = @_;

    my @current_tasks = @{ $stack };
    push @current_tasks, $callback;

    return \@current_tasks;
}

sub _run_before_stack
{
    my ( $stack ) = @_;

    foreach my $callback ( @{ $stack // [] } )
    {
        $callback->();
    };

    return;
}

sub _run_after_stack
{
    my ( $stack ) = @_;
    
    foreach my $callback ( reverse @{ $stack // [] } )
    {
        $callback->();
    };

    return;
}

1;
