package TestApp::Controller::Action::Chained::Bar;

use strict;
use warnings;

use base qw/Catalyst::Controller/;

#
#   Redispatching between controllers that are not in a parent/child
#   relation. This is the root.
#
sub cross1 :PathPart('chained/cross') :CaptureArgs(1) :Chained('/') { }

1;
