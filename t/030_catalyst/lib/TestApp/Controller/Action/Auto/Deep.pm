package TestApp::Controller::Action::Auto::Deep;

use strict;
use base 'TestApp::Controller::Action';

sub auto : Private {
    my ( $self, $c ) = @_;
    return 1;
}

sub default : Private {
    my ( $self, $c ) = @_;
    $c->res->body( 'deep default' );
}

sub one : Local {
    my ( $self, $c ) = @_;
    $c->res->body( 'deep one' );
}

1;
