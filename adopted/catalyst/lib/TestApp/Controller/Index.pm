package TestApp::Controller::Index;

use strict;
use base 'Catalyst::Controller';

sub index : Private {
    my ( $self, $c ) = @_;
    $c->res->body( 'Index index' );
}

1;
