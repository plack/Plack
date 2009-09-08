package TestApp::Role;
use Moose::Role;
use namespace::clean -except => 'meta';

requires 'fully_qualified'; # Comes from TestApp::Plugin::FullyQualified

our $SETUP_FINALIZE = 0;
our $SETUP_DISPATCHER = 0;

before 'setup_finalize' => sub { $SETUP_FINALIZE++ };

before 'setup_dispatcher' => sub { $SETUP_DISPATCHER++ }; 

1;

