package TestApp::Controller::Action::Chained::PassedArgs;
use warnings;
use strict;

use base qw( Catalyst::Controller );

#
#   This controller builds a simple chain of three actions that
#   will output the arguments they got passed to @_ after the
#   context object. We do this to test if that passing works
#   as it should.
#

sub first  : PathPart('chained/passedargs/a') Chained('/') CaptureArgs(1) {
    my ( $self, $c, $arg ) = @_;
    $c->stash->{ passed_args } = [ $arg ];
}

sub second : PathPart('b') Chained('first') CaptureArgs(1) {
    my ( $self, $c, $arg ) = @_;
    push @{ $c->stash->{ passed_args } }, $arg;
}

sub third  : PathPart('c') Chained('second') Args(1) {
    my ( $self, $c, $arg ) = @_;
    push @{ $c->stash->{ passed_args } }, $arg;
}

sub end : Private {
    my ( $self, $c ) = @_;
    $c->response->body( join '; ', @{ $c->stash->{ passed_args } } );
}

1;
