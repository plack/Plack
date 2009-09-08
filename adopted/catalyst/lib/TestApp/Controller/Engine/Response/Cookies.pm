package TestApp::Controller::Engine::Response::Cookies;

use strict;
use base 'Catalyst::Controller';

sub one : Local {
    my ( $self, $c ) = @_;
    $c->res->cookies->{catalyst} = { value => 'cool',     path => '/bah' };
    $c->res->cookies->{cool}     = { value => 'catalyst', path => '/' };
    $c->forward('TestApp::View::Dump::Request');
}

sub two : Local {
    my ( $self, $c ) = @_;
    $c->res->cookies->{catalyst} = { value => 'cool',     path => '/bah' };
    $c->res->cookies->{cool}     = { value => 'catalyst', path => '/' };
    $c->res->redirect('http://www.google.com/');
}

sub three : Local {
    my ( $self, $c ) = @_;

    $c->res->cookies->{object} = CGI::Simple::Cookie->new(
        -name => "this_is_the_real_name",
        -value => [qw/foo bar/],
    );

    $c->res->cookies->{hash} = {
        value => [qw/a b c/],
    };

    $c->forward('TestApp::View::Dump::Request');
}

1;
