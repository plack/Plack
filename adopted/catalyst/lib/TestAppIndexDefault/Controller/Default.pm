package TestAppIndexDefault::Controller::Default;

use base 'Catalyst::Controller';

sub default : Private {
    my ($self, $c) = @_;
    $c->res->body('default_default');
}

sub path_one_arg : Path('/default/') Args(1) {
    my ($self, $c) = @_;
    $c->res->body('default_path_one_arg');
}

1;
