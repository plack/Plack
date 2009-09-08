package TestAppChainedAbsolutePathPart::Controller::Foo;

use strict;
use warnings;

use base qw/Catalyst::Controller/;

sub foo : Chained PathPart('/foo/bar') Args(1) { }

1;
