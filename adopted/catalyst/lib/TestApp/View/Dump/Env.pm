package TestApp::View::Dump::Env;

use strict;
use base qw[TestApp::View::Dump];

sub process {
    my ( $self, $c ) = @_;
    return $self->SUPER::process( $c, $c->engine->env, 1 );
}

1;

