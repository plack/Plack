package TestApp::Controller::Moose::MethodModifiers;
use Moose;
BEGIN { extends qw/TestApp::Controller::Moose/; }

after get_attribute => sub {
    my ($self, $c) = @_;
    $c->response->header( 'X-Catalyst-Test-After' => 'after called' );
};

1;
