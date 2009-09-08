package TestApp::Controller::Action::Chained::ParentChain;
use warnings;
use strict;

use base qw/ Catalyst::Controller /;

#
#   Chains to the action /action/chained/parentchain in the
#   Action::Chained controller.
#
sub child :Chained('.') :Args(1) { }

# Should be at /chained/rootdef/*/chained_rel/*/*
sub chained_rel :Chained('../one') Args(2) {
}

# Should chain to loose in parent namespace - i.e. at /chained/loose/*/loose/*/*
sub loose : ChainedParent Args(2) {
}

# Should be at /chained/cross/*/up_down/*
sub up_down : Chained('../bar/cross1') Args(1) {
}

1;
