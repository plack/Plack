package TestApp::Controller::Action::Action;

use strict;
use base 'TestApp::Controller::Action';

__PACKAGE__->config( actions => { action_action_five => { ActionClass => '+Catalyst::Action::TestBefore' } } );

sub action_action_one : Global : ActionClass('TestBefore') {
    my ( $self, $c ) = @_;
    $c->res->header( 'X-Action', $c->stash->{test} );
    $c->forward('TestApp::View::Dump::Request');
}

sub action_action_two : Global : ActionClass('TestAfter') {
    my ( $self, $c ) = @_;
    $c->stash->{after_message} = 'awesome';
    $c->forward('TestApp::View::Dump::Request');
}

sub action_action_three : Global : ActionClass('+TestApp::Action::TestBefore') {
    my ( $self, $c ) = @_;
    $c->forward('TestApp::View::Dump::Request');
}

sub action_action_four : Global : MyAction('TestMyAction') {
    my ( $self, $c ) = @_;
    $c->forward('TestApp::View::Dump::Request');
}

sub action_action_five : Global {
    my ( $self, $c ) = @_;
    $c->res->header( 'X-Action', $c->stash->{test} );
    $c->forward('TestApp::View::Dump::Request');
}

sub action_action_six : Global : ActionClass('~TestMyAction') {
    my ( $self, $c ) = @_;
    $c->forward('TestApp::View::Dump::Request');
}

1;
