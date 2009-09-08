package TestApp::View::Dump::Request;

use strict;
use base qw[TestApp::View::Dump];

sub process {
    my ( $self, $c ) = @_;
    return $self->SUPER::process( $c, $c->request );
}

1;
