package DeprecatedTestApp;

use strict;
use Catalyst qw/
    Test::Deprecated
/;

our $VERSION = '0.01';

__PACKAGE__->config( name => 'DeprecatedTestApp', root => '/some/dir' );

__PACKAGE__->setup;

1;
