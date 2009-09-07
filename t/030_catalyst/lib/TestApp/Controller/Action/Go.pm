package TestApp::Controller::Action::Go;

use strict;
use base 'TestApp::Controller::Action';

sub one : Local {
    my ( $self, $c ) = @_;
    $c->go('two');
}

sub two : Private {
    my ( $self, $c ) = @_;
    $c->go('three');
}

sub three : Local {
    my ( $self, $c ) = @_;
    $c->go( $self, 'four' );
}

sub four : Private {
    my ( $self, $c ) = @_;
    $c->go('/action/go/five');
}

sub five : Local {
    my ( $self, $c ) = @_;
    $c->forward('View::Dump::Request');
}

sub inheritance : Local {
    my ( $self, $c ) = @_;
    $c->go('/action/inheritance/a/b/default');
}

sub global : Local {
    my ( $self, $c ) = @_;
    $c->go('/global_action');
}

sub with_args : Local {
    my ( $self, $c, $arg ) = @_;
    $c->go( 'args', [$arg] );
}

sub with_method_and_args : Local {
    my ( $self, $c, $arg ) = @_;
    $c->go( qw/TestApp::Controller::Action::Go args/, [$arg] );
}

sub args : Local {
    my ( $self, $c, $val ) = @_;
    die "passed argument does not match args" unless $val eq $c->req->args->[0];
    $c->res->body($val);
}

sub go_die : Local {
    my ( $self, $c, $val ) = @_;
    eval { $c->go( 'args', [qq/new/] ) };
    $c->res->body( $@ ? $@ : "go() did not die" );
    die $Catalyst::GO;
}

sub go_chained : Local {
    my ( $self, $c, $val ) = @_;
    $c->go('/action/chained/foo/spoon', ['captureme'], [qw/arg1 arg2/]);
}

sub view : Local {
    my ( $self, $c, $val ) = @_;
    eval { $c->go('View::Dump') };
    $c->res->body( $@ ? $@ : "go() did not die" );
}

sub model : Local {
    my ( $self, $c, $val ) = @_;
    eval { $c->go('Model::Foo') };
    $c->res->body( $@ ? $@ : "go() did not die" );
}

sub args_embed_relative : Local {
    my ( $self, $c ) = @_;
    $c->go('embed/ok');
}

sub args_embed_absolute : Local {
    my ( $self, $c ) = @_;
    $c->go('/action/go/embed/ok');
}

sub embed : Local {
    my ( $self, $c, $ok ) = @_;
    $ok ||= 'not ok';
    $c->res->body($ok);
}

sub class_go_test_action : Local {
    my ( $self, $c ) = @_;
    $c->go(qw/TestApp/);
}

1;
