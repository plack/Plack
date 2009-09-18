package Plack::Middleware::XFramework;
use strict;
use warnings;
use base qw/Plack::Middleware/;
__PACKAGE__->mk_accessors(qw/framework/);

sub app_handler {
    my $self = shift;

    return sub {
        my $res = $self->app->( @_ );
        push @{$res->[1]}, 'X-Framework' => $self->framework;
        $res;
    };
}

1;
