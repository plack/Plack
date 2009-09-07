package TestApp::Controller::Engine::Response::Errors;

use strict;
use base 'Catalyst::Controller';

sub one : Relative {
    my ( $self, $c ) = @_;
    my $a = 0;
    my $b = 0;
    my $t = $a / $b;
}

sub two : Relative {
    my ( $self, $c ) = @_;
    $c->forward('/non/existing/path');
}

sub three : Relative {
    my ( $self, $c ) = @_;
    die("I'm going to die!\n");
}

1;
