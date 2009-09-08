package TestApp::View::Dump::Body;

use strict;
use base qw[TestApp::View::Dump];

sub process {
    my ( $self, $c ) = @_;
    return $self->SUPER::process( $c, $c->request->{_body} ); # FIXME, accessor doesn't work?
}

1;
