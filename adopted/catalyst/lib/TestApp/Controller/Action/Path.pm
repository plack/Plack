package TestApp::Controller::Action::Path;

use strict;
use base 'TestApp::Controller::Action';

__PACKAGE__->config(
    actions => {
      'one' => { 'Path' => [ 'a path with spaces' ] },
      'two' => { 'Path' => "åäö" },
      'six' => { 'Local' => undef },
    },
);

sub one : Action Path("this_will_be_overriden") {
    my ( $self, $c ) = @_;
    $c->forward('TestApp::View::Dump::Request');
}

sub two : Action {
    my ( $self, $c ) = @_;
    $c->forward('TestApp::View::Dump::Request');
}

sub three :Path {
    my ( $self, $c ) = @_;
    $c->forward('TestApp::View::Dump::Request');
}

sub four : Path( 'spaces_near_parens_singleq' ) {
    my ( $self, $c ) = @_;
    $c->forward('TestApp::View::Dump::Request');
}

sub five : Path( "spaces_near_parens_doubleq" ) {
    my ( $self, $c ) = @_;
    $c->forward('TestApp::View::Dump::Request');
}

sub six {
    my ( $self, $c ) = @_;
    $c->forward('TestApp::View::Dump::Request');
}

1;
