package TestApp::Controller::Action::End;

use strict;
use base 'TestApp::Controller::Action';

sub end : Private {
    my ( $self, $c ) = @_;
}

sub default : Private {
    my ( $self, $c ) = @_;
    $c->forward('TestApp::View::Dump::Request');
}

1;
