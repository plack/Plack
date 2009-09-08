package TestApp::Controller::Action::Detach;

use strict;
use base 'TestApp::Controller::Action';

sub one : Local {
    my ( $self, $c ) = @_;
    $c->detach('two');
    $c->forward('error');
}

sub two : Private {
    my ( $self, $c ) = @_;
    $c->forward('TestApp::View::Dump::Request');
}

sub error : Local {
    my ( $self, $c ) = @_;
    $c->res->output('error');
}

sub path : Local {
    my ( $self, $c ) = @_;
    $c->detach('/action/detach/two');
    $c->forward('error');
}

sub with_args : Local {
    my ( $self, $c, $orig ) = @_;
    $c->detach( 'args', [qq/new/] );
}

sub with_method_and_args : Local {
    my ( $self, $c, $orig ) = @_;
    $c->detach( qw/TestApp::Controller::Action::Detach args/, [qq/new/] );
}

sub args : Local {
    my ( $self, $c, $val ) = @_;
    die "Expected argument 'new', got '$val'" unless $val eq 'new';
    die "passed argument does not match args" unless $val eq $c->req->args->[0];
    $c->res->body( $c->req->args->[0] );
}

1;
