package TestApp::Controller::Engine::Response::Large;

use strict;
use base 'Catalyst::Controller';

sub one : Relative {
    my ( $self, $c ) = @_;
    $c->res->output( 'x' x (100 * 1024) ); 
}

sub two : Relative {
    my ( $self, $c ) = @_;
    $c->res->output( 'y' x (1024 * 1024) );
}

1;
