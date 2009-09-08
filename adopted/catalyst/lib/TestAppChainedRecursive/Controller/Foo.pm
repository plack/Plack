package TestAppChainedRecursive::Controller::Foo;

use strict;
use warnings;

use base qw/Catalyst::Controller/;

sub foo : Chained('bar') CaptureArgs(1) { }
sub bar : Chained('foo') CaptureArgs(1) { }

1;
