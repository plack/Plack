use strict;
use warnings;

package My::AttributesBaseClass;
use base qw( Catalyst::Controller );

sub fetch : Chained('/') PathPrefix CaptureArgs(1) {

}

sub view : PathPart Chained('fetch') Args(0) {

}

sub foo {    # no attributes

}

package TestApp::Controller::Attributes;
use base qw(My::AttributesBaseClass);

sub view {    # override attributes to "hide" url

}

sub foo : Local {

}

1;
