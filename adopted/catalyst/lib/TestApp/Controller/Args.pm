package TestApp::Controller::Args;

use strict;
use base 'Catalyst::Controller';

sub args :Local  {
    my ( $self, $c ) = @_;
    $c->res->body( join('',@{$c->req->args}) );
}

sub params :Local {
    my ( $self, $c ) = splice @_, 0, 2;
    $c->res->body( join('',@_) );
}

1;
