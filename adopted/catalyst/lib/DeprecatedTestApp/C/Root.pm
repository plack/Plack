package DeprecatedTestApp::C::Root;
use strict;
use warnings;
use base qw/Catalyst::Controller/;

__PACKAGE__->config->{namespace} = '';

sub index : Private {
    my ( $self, $c ) = @_;
    $c->res->body('root index');
}

sub req_user : Local {
    my ( $self, $c ) = @_;
    $c->res->body('REMOTE_USER = ' . $c->req->user);
}

1;
