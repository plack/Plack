package TestAppIndexDefault::Controller::IndexPrivate;

use base 'Catalyst::Controller';

sub index : Private {
    my ($self, $c) = @_;
    $c->res->body('index_private');
}

1;
