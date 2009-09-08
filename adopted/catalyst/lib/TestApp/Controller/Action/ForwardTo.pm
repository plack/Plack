package TestApp::Controller::Action::ForwardTo;

use strict;
use base 'TestApp::Controller::Action';

sub uri_check : Private {
    my ( $self, $c ) = @_;
    $c->res->body( $c->uri_for('foo/bar')->path );
}

1;
