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

* 'before all' will be executed IMMEDIATELY. This means:
** 'before all' routines MUST be added at the beginning of a 'describe'

Test::Spec appears to run 'before each' blocks before 'before all' within nested 'describe' blocks.
The documentation in Test::Spec is not clear that it runs nested blocks in this manner. TestCase::Spec DOES NOT does not match this behaviour.

=head1 COPYRIGHT AND LICENSE

TestCase::Spec is Copyright (C) 2018-2020, Martin Pritchard.

This module is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0.
This program is distributed in the hope that it will be useful, but it is provided "as is" and without any express or implied warranties.

For details, see the full text of the license in the file LICENSE.

=cut

use strict;
use warnings;

use Test::MockModule;

use Carp qw( croak );
use Exporter qw( import );
use List::Util qw( any );
use Test::More;
use Try::Tiny;

use TestCase::Spec::Context;

our $VERSION = 1.00;

our @EXPORT = qw(
    after
    before
    describe
    it
    xit
);

our $AFTER_ALL   = [];
our $AFTER_EACH  = [];
our $BEFORE_EACH = [];
our $CONTEXT     = '';

our $HOOK;
our $ENTERED = 0;

sub test_name
{
    return $CONTEXT;
}

sub after
{
    my ( $when, $callback ) = @_;

    croak 'after must be used within a describe block' unless $ENTERED;

    my $error = _before_or_after( 'after', $when, $callback );
    croak $error if $error;

    return;
}

sub before
{
    my ( $when, $callback ) = @_;

    croak 'before must be used within a describe block' unless $ENTERED;

    my $error = _before_or_after( 'before', $when, $callback );
    croak $error if $error;

    return;
}

sub describe
{
    my ( $context, $callback ) = @_;

    croak "context not provided"                           unless( defined $context and $context ne '' );
    croak "expected subroutine reference as last argument" unless( ref $callback eq 'CODE' );

    return _describe( $context, $callback );
}

sub _describe
{
    my ( $context, $callback ) = @_;

    local $BEFORE_EACH = $BEFORE_EACH;
    local $AFTER_EACH  = $AFTER_EACH;
    local $AFTER_ALL   = [];
    local $CONTEXT     = _extend_context( $context );

    unless( $ENTERED )
    {
        # Hook our custom Test::Builder into Test::More to allow us to automatically name tests
        $HOOK = Test::MockModule->new( 'Test::Builder' );
        $HOOK->redefine( ok      => sub { my ( $obj, $test, $name ) = @_; return $HOOK->original( 'ok' )->( $obj, $test, $name || test_name() ) } );
        $HOOK->redefine( caller  => sub { my ( $obj, $height ) = @_; return $HOOK->original( 'caller' )->( $obj, ( $height || 0 ) + 2 ); } );
        $HOOK->redefine( in_todo => sub { return ( $TODO ) ? 1 : 0 } );
        $HOOK->redefine( todo    => sub { return $TODO } );
    };

    $ENTERED++;

    $callback->();

    _run_after_stack( $AFTER_ALL );

    $ENTERED--;

    if( $ENTERED == 0 )
    {
        $HOOK->unmock_all;
    }

    return;
}

sub it
{
    my ( $context, $callback ) = @_;

    unless( $ENTERED )
    {
        return _describe( '', sub { it( $context, $callback ) } );
    }

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
        if( $type eq 'before' )
        {
            $callback->();
        }
        else
        {
            $AFTER_ALL = _extend_stack( $AFTER_ALL, $callback );
        }
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
