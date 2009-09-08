package TestAppOnDemand::Controller::Body;

use strict;
use base 'Catalyst::Controller';

use Data::Dump ();

sub body_params : Local {
    my ( $self, $c ) = @_;

    $c->res->body( Data::Dump::dump( $c->req->body_parameters ) );
}

sub query_params : Local {
    my ( $self, $c ) = @_;

    $c->res->body( Data::Dump::dump( $c->req->query_parameters ) );
}

sub params : Local {
    my ( $self, $c ) = @_;

    $c->res->body( Data::Dump::dump( $c->req->parameters ) );
}

sub read : Local {
    my ( $self, $c ) = @_;
    
    # read some data
    my @chunks;
    
    while ( my $data = $c->read( 10_000 ) ) {
        push @chunks, $data;
    }

    $c->res->content_type( 'text/plain');
    
    $c->res->body( join ( '|', map { length $_ } @chunks ) );
}

1;
