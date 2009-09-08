package TestApp::Controller::Engine::Response::Headers;

use strict;
use base 'Catalyst::Controller';

sub one : Relative {
    my ( $self, $c ) = @_;
    $c->res->header( 'X-Header-Catalyst' => 'Cool' );
    $c->res->header( 'X-Header-Cool'     => 'Catalyst' );
    $c->res->header( 'X-Header-Numbers'  => join ', ', 1 .. 10 );
    $c->forward('TestApp::View::Dump::Request');
}

1;
