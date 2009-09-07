package Catalyst::Plugin::Test::Deprecated;

use strict;
use warnings;
use NEXT;

sub prepare {
    my $class = shift;
    # Note: This use of NEXT is deliberately left here (without a use NEXT)
    #       to ensure back compat, as NEXT always used to be loaded, but
    #       is now replaced by Class::C3::Adopt::NEXT.
    my $c = $class->NEXT::prepare(@_);
    $c->response->header( 'X-Catalyst-Plugin-Deprecated' => 1 );

    return $c;
}

1;
