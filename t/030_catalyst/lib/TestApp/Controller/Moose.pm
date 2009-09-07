package TestApp::Controller::Moose;

use Moose;

use namespace::clean -except => 'meta';

BEGIN { extends qw/Catalyst::Controller/; }
use MooseX::MethodAttributes; # FIXME - You need to say this if you have
                              #         modifiers so that you get the correct
                              #         method metaclass, why does the modifier
                              #         on MODIFY_CODE_ATTRIBUTES not work.

has attribute => (
    is      => 'ro',
    default => 42,
);

sub get_attribute : Local {
    my ($self, $c) = @_;
    $c->response->body($self->attribute);
}

sub with_local_modifier : Local {
    my ($self, $c) = @_;
    $c->forward('get_attribute');
}

before with_local_modifier => sub {
    my ($self, $c) = @_;
    $c->response->header( 'X-Catalyst-Test-Before' => 'before called' );
};

1;
