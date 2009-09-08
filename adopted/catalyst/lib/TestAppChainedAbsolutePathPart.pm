package TestAppChainedAbsolutePathPart;

use strict;
use Catalyst qw/
    Test::Errors 
    Test::Headers 
/;
use Catalyst::Utils;

our $VERSION = '0.01';

TestAppChainedAbsolutePathPart
    ->config( 
        name => 'TestAppChainedAbsolutePathPart',
        root => '/some/dir'
    );

TestAppChainedAbsolutePathPart->setup;

1;
