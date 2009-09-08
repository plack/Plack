package TestApp::Controller::Engine::Response::Redirect;

use strict;
use base 'Catalyst::Controller';

sub one : Relative {
    my ( $self, $c ) = @_;
    $c->response->redirect('/test/writing/is/boring');
}

sub two : Relative {
    my ( $self, $c ) = @_;
    $c->response->redirect('http://www.google.com/');
}

sub three : Relative {
    my ( $self, $c ) = @_;
    $c->response->redirect('http://www.google.com/');
    $c->response->status(301); # Moved Permanently
}

sub four : Relative {
    my ( $self, $c ) = @_;
    $c->response->redirect('http://www.google.com/');
    $c->response->status(307); # Temporary Redirect
}

1;

