package TestApp::Model::ClosuresInConfig;
use Moose;
use namespace::clean -except => 'meta';

extends 'TestApp::Model';

# Note - don't call ->config in here until the constructor calls it to
#        retrieve config, so that we get the 'copy from parent' path, 
#        and ergo break due to the closure if dclone is used there..

__PACKAGE__->meta->make_immutable;

