package TestApp::Controller::Dump;

use strict;
use base 'Catalyst::Controller';

sub default : Action Private {
    my ( $self, $c ) = @_;
    $c->forward('TestApp::View::Dump');
}

sub env : Action Relative {
    my ( $self, $c ) = @_;
    $c->forward('TestApp::View::Dump::Env');
}

sub request : Action Relative {
    my ( $self, $c ) = @_;
    $c->req->params(undef); # Should be a no-op, and be ignored.
                            # Back compat test for 5.7
    $c->forward('TestApp::View::Dump::Request');
}

sub response : Action Relative {
    my ( $self, $c ) = @_;
    $c->forward('TestApp::View::Dump::Response');
}

sub body : Action Relative {
    my ( $self, $c ) = @_;
    $c->forward('TestApp::View::Dump::Body');
}

1;
