package TestApp::Action::TestMyAction;

use strict;
use warnings;

use base qw/Catalyst::Action/;

sub execute {
    my $self = shift;
    my ( $controller, $c, $test ) = @_;
    $c->res->header( 'X-TestAppActionTestMyAction', 'MyAction works' );
    $c->res->header( 'X-Component-Name-Action', $controller->catalyst_component_name);
    $c->res->header( 'X-Component-Instance-Name-Action', ref($controller));
    $c->res->header( 'X-Class-In-Action', $self->class);
    $self->next::method(@_);
}

1;

