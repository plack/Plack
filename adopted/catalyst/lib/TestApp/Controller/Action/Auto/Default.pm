package TestApp::Controller::Action::Auto::Default;

use strict;
use base 'TestApp::Controller::Action';

sub begin : Private { }

sub auto : Private {
    my ( $self, $c ) = @_;
    $c->stash->{auto_ran}++;
    return 1;
}

sub default : Private {
    my ( $self, $c ) = @_;
    $c->res->body( sprintf 'default (auto: %d)', $c->stash->{auto_ran} );
}

sub end : Private { }

1;

