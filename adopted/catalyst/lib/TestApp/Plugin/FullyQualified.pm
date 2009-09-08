package TestApp::Plugin::FullyQualified;

use strict;

sub fully_qualified {
    my $c = shift;

    $c->stash->{fully_qualified} = 1;

    return $c;
}

1;
