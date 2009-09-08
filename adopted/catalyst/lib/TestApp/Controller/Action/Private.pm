package TestApp::Controller::Action::Private;

use strict;
use base 'TestApp::Controller::Action';

sub default : Private {
    my ( $self, $c ) = @_;
    $c->res->output('access denied');
}

sub one : Private { 
    my ( $self, $c ) = @_;
    $c->res->output('access allowed');
}

sub two : Private Relative {
    my ( $self, $c ) = @_;
    $c->res->output('access allowed');
}

sub three : Private Absolute {
    my ( $self, $c ) = @_;
    $c->res->output('access allowed');
}

sub four : Private Path('/action/private/four') {
    my ( $self, $c ) = @_;
    $c->res->output('access allowed');
}

sub five : Private Path('five') {
    my ( $self, $c ) = @_;
    $c->res->output('access allowed');
}

1;
