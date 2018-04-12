package TestCase::Spec;

use Exporter qw( import );
use Test::More;

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

    my $current_context = $CONTEXT;
    $current_context .= ' ' unless $current_context eq '';
    local $CONTEXT = $current_context . $context;

    $callback->();

    return;
}

sub it
{
    my ( $context, $callback ) = @_;

    my $current_context = $CONTEXT;
    $current_context .= ' ' unless $current_context eq '';
    local $CONTEXT = $current_context . $context;

    if( defined $callback )
    {
        $callback->();
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

    my $current_context = $CONTEXT;
    $current_context .= ' ' unless $current_context eq '';
    local $CONTEXT = $current_context . $context;

    local $TODO = "(disabled)";
    ok( 0, $CONTEXT );

    return;
}

1;
