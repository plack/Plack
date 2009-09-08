package TestApp::Controller::Action::Visit;

use strict;
use base 'TestApp::Controller::Action';

sub one : Local {
    my ( $self, $c ) = @_;
    $c->visit('two');
}

sub two : Private {
    my ( $self, $c ) = @_;
    $c->visit('three');
}

sub three : Local {
    my ( $self, $c ) = @_;
    $c->visit( $self, 'four' );
}

sub four : Private {
    my ( $self, $c ) = @_;
    $c->visit('/action/visit/five');
}

sub five : Local {
    my ( $self, $c ) = @_;
    $c->forward('View::Dump::Request');
}

sub inheritance : Local {
    my ( $self, $c ) = @_;
    $c->visit('/action/inheritance/a/b/default');
}

sub global : Local {
    my ( $self, $c ) = @_;
    $c->visit('/global_action');
}

sub with_args : Local {
    my ( $self, $c, $arg ) = @_;
    $c->visit( 'args', [$arg] );
}

sub with_method_and_args : Local {
    my ( $self, $c, $arg ) = @_;
    $c->visit( qw/TestApp::Controller::Action::Visit args/, [$arg] );
}

sub args : Local {
    my ( $self, $c, $val ) = @_;
    die "passed argument does not match args" unless $val eq $c->req->args->[0];
    $c->res->body($val);
}

sub visit_die : Local {
    my ( $self, $c, $val ) = @_;
    eval { $c->visit( 'args', [qq/new/] ) };
    $c->res->body( $@ ? $@ : "visit() doesn't die" );
}

sub visit_chained : Local {
    my ( $self, $c, $val, $capture, @args ) = @_;
    my @cap_and_args = ([$capture], [@args]);
      $val eq 1 ? $c->visit( '/action/chained/foo/spoon',                                 @cap_and_args)
    : $val eq 2 ? $c->visit( qw/ Action::Chained::Foo spoon /,                            @cap_and_args)
    :             $c->visit( $c->controller('Action::Chained::Foo')->action_for('spoon'), @cap_and_args)
}

sub view : Local {
    my ( $self, $c, $val ) = @_;
    eval { $c->visit('View::Dump') };
    $c->res->body( $@ ? $@ : "visit() did not die" );
}

sub model : Local {
    my ( $self, $c, $val ) = @_;
    eval { $c->visit('Model::Foo') };
    $c->res->body( $@ ? $@ : "visit() did not die" );
}

sub args_embed_relative : Local {
    my ( $self, $c ) = @_;
    $c->visit('embed/ok');
}

sub args_embed_absolute : Local {
    my ( $self, $c ) = @_;
    $c->visit('/action/visit/embed/ok');
}

sub embed : Local {
    my ( $self, $c, $ok ) = @_;
    $ok ||= 'not ok';
    $c->res->body($ok);
}

sub class_visit_test_action : Local {
    my ( $self, $c ) = @_;
    $c->visit(qw/TestApp/);
}

1;
