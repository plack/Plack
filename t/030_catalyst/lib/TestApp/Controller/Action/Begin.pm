package TestApp::Controller::Action::Begin;

use strict;
use base 'TestApp::Controller::Action';

sub begin : Private {
    my ( $self, $c ) = @_;
    $self->SUPER::begin($c);
}

sub default : Private {
    my ( $self, $c ) = @_;
    $c->forward('TestApp::View::Dump::Request');
}

1;
