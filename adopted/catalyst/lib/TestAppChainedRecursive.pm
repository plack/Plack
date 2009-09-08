package TestAppChainedRecursive;

use strict;
use Catalyst qw/
    Test::Errors 
    Test::Headers 
/;
use Catalyst::Utils;

our $VERSION = '0.01';

TestAppChainedRecursive->config(
    name => 'TestAppChainedRecursive',
    root => '/some/dir'
);

TestAppChainedRecursive->setup;

1;
