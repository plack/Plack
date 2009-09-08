package TestApp::Controller::Action::Chained::Auto::Detach;
use warnings;
use strict;

use base qw( Catalyst::Controller );

#
#   For testing behaviour of a detaching auto action in a chain.
#
sub auto    : Private {
    my ( $self, $c ) = @_;
    $c->detach( '/action/chained/auto/fw3' );
    return 1;
}

sub detachend  : Chained('/action/chained/auto/dt1') Args(1) { }

1;
