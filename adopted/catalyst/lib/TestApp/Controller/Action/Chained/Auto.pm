package TestApp::Controller::Action::Chained::Auto;
use warnings;
use strict;

use base qw( Catalyst::Controller );

#
#   Provided for sub-auto tests. This just always returns true.
#
sub auto    : Private { 1 }

#
#   Simple chains with auto actions returning 1 and 0
#
sub foo     : Chained PathPart('chained/autochain1') CaptureArgs(1) { }
sub bar     : Chained PathPart('chained/autochain2') CaptureArgs(1) { }

#
#   Detaching out of an auto action.
#
sub dt1     : Chained PathPart('chained/auto_detach') CaptureArgs(1) { }

#
#   Forwarding out of an auto action.
#
sub fw1     : Chained PathPart('chained/auto_forward') CaptureArgs(1) { }

#
#   Target for dispatch and forward tests.
#
sub fw3     : Private { }

1;
