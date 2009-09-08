package TestApp::Controller::Action::Chained::PathPrefix;

use strict;
use warnings;

use base qw/Catalyst::Controller/;

# this is kinda the same thing as: sub instance : Path {}
# it should respond to: /action/chained/pathprefix/*
sub instance : Chained('/') PathPrefix Args(1) { }

1;
