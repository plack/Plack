package TestApp::Controller::Action::Default;

use strict;
use base 'TestApp::Controller::Action';

sub default : Private {
    my ( $self, $c ) = @_;
    $c->forward('TestApp::View::Dump::Request');
}

1;
