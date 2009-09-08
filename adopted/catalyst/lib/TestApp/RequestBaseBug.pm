package TestApp::RequestBaseBug;

use base 'Catalyst::Request';

sub uri {
    my $self = shift;

# this goes into infinite mutual recursion
    $self->base;

    $self->SUPER::uri(@_)
}

1;
