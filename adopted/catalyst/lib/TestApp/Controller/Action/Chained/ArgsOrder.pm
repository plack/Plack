package TestApp::Controller::Action::Chained::ArgsOrder;
use warnings;
use strict;

use base qw( Catalyst::Controller );

#
#   This controller builds a simple chain of three actions that
#   will output the arguments they got passed to @_ after the
#   context object. We do this to test if that passing works
#   as it should.
#

sub base  :Chained('/') PathPart('argsorder') CaptureArgs(0) {
    my ( $self, $c, $arg ) = @_;
    push @{ $c->stash->{ passed_args } }, 'base', $arg;
}

sub index :Chained('base') PathPart('') Args(0) {
    my ( $self, $c, $arg ) = @_;
    push @{ $c->stash->{ passed_args } }, 'index', $arg;
}

sub all  :Chained('base') PathPart('') Args() {
    my ( $self, $c, $arg ) = @_;
    push @{ $c->stash->{ passed_args } }, 'all', $arg;
}

sub end : Private {
    my ( $self, $c ) = @_;
    no warnings 'uninitialized';
    $c->response->body( join '; ', @{ $c->stash->{ passed_args } } );
}

1;
