package TestApp::Controller::Priorities::MultiMethod;

use strict;
use warnings;
use base qw/Catalyst::Controller/;

sub auto :Private {
    my ($self, $c) = @_;
    $c->res->body(join(' ', $c->action->name, @{$c->req->args}));
    return 1;
}

sub zero :Path :Args(0) { }

sub one :Path :Args(1) { }

sub two :Path :Args(2) { }

sub not_def : Path { }

1;
