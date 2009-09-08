package TestAppIndexDefault::Controller::Root;

use base 'Catalyst::Controller';

__PACKAGE__->config->{namespace} = '';

sub default : Private {
    my ($self, $c) = @_;
    $c->res->body('default');
}

sub path_one_arg : Path('/') Args(1) {
    my ($self, $c) = @_;
    $c->res->body('path_one_arg');
}

1;
