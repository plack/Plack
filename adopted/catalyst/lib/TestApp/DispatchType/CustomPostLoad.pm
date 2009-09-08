package TestApp::DispatchType::CustomPostLoad;
use strict;
use warnings;
use base qw/Catalyst::DispatchType::Path/;

# Never match anything..
sub match { }

1;

