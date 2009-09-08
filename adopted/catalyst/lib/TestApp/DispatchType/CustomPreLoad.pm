package TestApp::DispatchType::CustomPreLoad;
use strict;
use warnings;
use base qw/Catalyst::DispatchType::Path/;

# Never match anything..
sub match { }

1;

