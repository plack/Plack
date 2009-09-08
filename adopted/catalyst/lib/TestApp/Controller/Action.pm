package TestApp::Controller::Action;

use strict;
use base 'Catalyst::Controller';

sub begin : Private {
    my ( $self, $c ) = @_;
    $c->res->header( 'X-Test-Class' => ref($self) );
    $c->response->content_type('text/plain; charset=utf-8');
}

sub default : Private {
    my ( $self, $c ) = @_;
    $c->res->output("Error - TestApp::Controller::Action\n");
    $c->res->status(404);
}

1;
