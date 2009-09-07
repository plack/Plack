package TestApp::Controller::Action::Chained::Root;

use strict;
use warnings;

use base qw( Catalyst::Controller );

__PACKAGE__->config->{namespace} = '';

sub rootsub     : PathPart Chained( '/' )       CaptureArgs( 1 ) { }
sub endpointsub : PathPart Chained( 'rootsub' ) Args( 1 )        { }

1;
