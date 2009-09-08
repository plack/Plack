package TestAppWithMeta;
use strict;
use warnings;
use Catalyst;

no warnings 'redefine';
sub meta {}
use warnings 'redefine';

__PACKAGE__->setup;

1;

