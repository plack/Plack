package TestApp::Controller::Action::Auto::Abort;

use strict;
use base 'TestApp::Controller::Action';

sub auto : Private {
    my ( $self, $c ) = @_;
    return 0;
}

sub default : Private {
    my ( $self, $c ) = @_;
    $c->res->body( 'abort default' );
}

sub end : Private {
    my ( $self, $c ) = @_;
    $c->res->body( 'abort end' ) unless $c->res->body;
}

sub one : Local {
    my ( $self, $c ) = @_;
    $c->res->body( 'abort one' );
}

1;
