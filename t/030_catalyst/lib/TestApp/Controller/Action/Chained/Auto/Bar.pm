package TestApp::Controller::Action::Chained::Auto::Bar;
use warnings;
use strict;

use base qw( Catalyst::Controller );

#
#   Test chain reaction if auto action returns 0.
#
sub auto        : Private { 0 }

sub barend      : Chained('.') Args(1) { }

sub crossloose  : Chained PathPart('chained/auto_cross') CaptureArgs(1) { }

1;
