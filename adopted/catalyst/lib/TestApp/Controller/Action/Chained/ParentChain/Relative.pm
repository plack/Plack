package TestApp::Controller::Action::Chained::ParentChain::Relative;
use warnings;
use strict;

use base qw/ Catalyst::Controller /;

# using ../ to go up more than one level
sub chained_rel_two : Chained('../../one') Args(2) { }

1;
