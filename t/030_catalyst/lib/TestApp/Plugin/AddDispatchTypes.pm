package TestApp::Plugin::AddDispatchTypes;
use strict;
use warnings;
use MRO::Compat;

sub setup_dispatcher {
    my $class = shift;

    ### Load custom DispatchTypes, as done by Catalyst::Plugin::Server
    # There should be a waaay less ugly method for doing this,
    # FIXME in 5.9
    $class->next::method( @_ );
    $class->dispatcher->preload_dispatch_types(
        @{$class->dispatcher->preload_dispatch_types},
        qw/ +TestApp::DispatchType::CustomPreLoad /
    );
    $class->dispatcher->postload_dispatch_types(
        @{$class->dispatcher->postload_dispatch_types},
        qw/ +TestApp::DispatchType::CustomPostLoad /
    );

    return $class;
}

1;

