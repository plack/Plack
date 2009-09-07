package TestApp::Controller::Engine::Response::Print;

use strict;
use base 'Catalyst::Controller';

sub one :Relative {
    my ( $self, $c ) = @_;
    
    $c->res->print("foo");
}

sub two :Relative {
    my ( $self, $c ) = @_;

    $c->res->print(qw/foo bar/);
}

sub three :Relative {
    my ( $self, $c ) = @_;

    local $, = ',';
    $c->res->print(qw/foo bar baz/);
}

1;
