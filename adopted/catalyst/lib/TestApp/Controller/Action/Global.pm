package TestApp::Controller::Action::Global;

use strict;
use base 'TestApp::Controller::Action';

sub action_global_one : Action Absolute {
    my ( $self, $c ) = @_;
    $c->forward('TestApp::View::Dump::Request');
}

sub action_global_two : Action Global {
    my ( $self, $c ) = @_;
    $c->forward('TestApp::View::Dump::Request');
}

sub action_global_three : Action Path('/action_global_three') {
    my ( $self, $c ) = @_;
    $c->forward('TestApp::View::Dump::Request');
}

1;
