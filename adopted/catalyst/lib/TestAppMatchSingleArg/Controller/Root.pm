package TestAppMatchSingleArg::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller';

__PACKAGE__->config->{namespace} = '';

sub match_single : Path Args(1) {
    my ($self, $c) = @_;
    $c->res->body('Path Args(1)');
}

sub match_other : Path {
    my ($self, $c) = @_;
    $c->res->body('Path');
}

sub match_two : Path Args(2) {
    my ($self, $c) = @_;
    $c->res->body('Path Args(2)');
}

1;
