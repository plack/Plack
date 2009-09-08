package TestApp::Controller::Engine::Response::Status;

use strict;
use base 'Catalyst::Controller';

sub begin : Private {
    my ( $self, $c ) = @_;
    $c->response->content_type('text/plain');
    return 1;
}

sub s200 : Relative {
    my ( $self, $c ) = @_;
    $c->res->status(200);
    $c->res->output("200 OK\n");
}

sub s400 : Relative {
    my ( $self, $c ) = @_;
    $c->res->status(400);
    $c->res->output("400 Bad Request\n");
}

sub s403 : Relative {
    my ( $self, $c ) = @_;
    $c->res->status(403);
    $c->res->output("403 Forbidden\n");
}

sub s404 : Relative {
    my ( $self, $c ) = @_;
    $c->res->status(404);
    $c->res->output("404 Not Found\n");
}

sub s500 : Relative {
    my ( $self, $c ) = @_;
    $c->res->status(500);
    $c->res->output("500 Internal Server Error\n");
}

1;
