package TestAppIndexDefault::Controller::IndexChained;

use base 'Catalyst::Controller';

sub index : Chained('/') PathPart('indexchained') CaptureArgs(0) {}

sub index_endpoint : Chained('index') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->res->body('index_chained');
}

1;
