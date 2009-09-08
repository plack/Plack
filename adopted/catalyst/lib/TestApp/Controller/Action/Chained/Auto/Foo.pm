package TestApp::Controller::Action::Chained::Auto::Foo;
use warnings;
use strict;

use base qw( Catalyst::Controller );

#
#   Test chain reaction if auto action returns 1.
#
sub auto        : Private { 1 }

sub fooend      : Chained('.') Args(1) { }

sub crossend    : Chained('/action/chained/auto/bar/crossloose') Args(1) { }

1;
