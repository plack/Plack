package TestApp::Controller::Action::Chained::Auto::Forward;
use warnings;
use strict;

use base qw( Catalyst::Controller );

#
#   For testing behaviour of a forwarding auto action in a chain.
#
sub auto    : Private {
    my ( $self, $c ) = @_;
    $c->forward( '/action/chained/auto/fw3' );
    return 1;
}

sub forwardend  : Chained('/action/chained/auto/fw1') Args(1) { }

1;
