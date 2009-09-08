package TestAppOnDemand;

use strict;
use Catalyst qw/
    Test::Errors 
    Test::Headers 
/;
use Catalyst::Utils;

our $VERSION = '0.01';

__PACKAGE__->config(
    name            => __PACKAGE__,
    root            => '/some/dir',
    parse_on_demand => 1,
);

__PACKAGE__->setup;

1;
