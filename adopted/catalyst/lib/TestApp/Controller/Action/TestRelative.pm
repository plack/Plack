package TestApp::Controller::Action::TestRelative;

use strict;
use base 'TestApp::Controller::Action';

__PACKAGE__->config(
  path => 'action/relative'
);

sub relative : Local {
    my ( $self, $c ) = @_;
    $c->forward('/action/forward/one');
}

sub relative_two : Local {
    my ( $self, $c ) = @_;
    $c->forward( 'TestApp::Controller::Action::Forward', 'one' );
}

sub relative_go : Local {
    my ( $self, $c ) = @_;
    $c->go('/action/go/one');
}

sub relative_go_two : Local {
    my ( $self, $c ) = @_;
    $c->go( 'TestApp::Controller::Action::Go', 'one' );
}

sub relative_visit : Local {
    my ( $self, $c ) = @_;
    $c->visit('/action/visit/one');
}

sub relative_visit_two : Local {
    my ( $self, $c ) = @_;
    $c->visit( 'TestApp::Controller::Action::Visit', 'one' );
}

1;
