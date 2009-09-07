package TestApp::Controller::Action::Regexp;

use strict;
use base 'TestApp::Controller::Action';

sub one : Action Regex('^action/regexp/(\w+)/(\d+)$') {
    my ( $self, $c ) = @_;
    $c->forward('TestApp::View::Dump::Request');
}

sub two : Action LocalRegexp('^(\d+)/(\w+)$') {
    my ( $self, $c ) = @_;
    $c->forward('TestApp::View::Dump::Request');
}

sub three : Action LocalRegex('^(mandatory)(/optional)?$'){
    my ( $self, $c ) = @_;
    $c->forward('TestApp::View::Dump::Request');
}

sub four : Action Regex('^action/regexp/redirect/(\w+)/universe/(\d+)/everything$') {
    my ( $self, $c ) = @_;
    $c->res->redirect(
        $c->uri_for($c->action, $c->req->captures,
            @{$c->req->arguments}, $c->req->params
        )
    );
}

1;
