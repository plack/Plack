package TestApp;

use strict;
use warnings;

use Catalyst::Runtime 5.70;

use base qw/Catalyst/;

use Catalyst;

__PACKAGE__->setup();

sub _test {
    my $self = shift;
    $self->_method_which_does_not_exist;
}

__PACKAGE__->_test;

1;

