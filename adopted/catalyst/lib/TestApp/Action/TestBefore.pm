package TestApp::Action::TestBefore;

use strict;
use warnings;

use base qw/Catalyst::Action/;

sub execute {
    my $self = shift;
    my ( $controller, $c, $test ) = @_;
    $c->res->header( 'X-TestAppActionTestBefore', $test );
    $self->next::method( @_ );
}

1;
