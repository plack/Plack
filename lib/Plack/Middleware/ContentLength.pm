package Plack::Middleware::ContentLength;
use strict;
use warnings;
use base qw( Plack::Middleware );

use Plack::Util;

sub call {
    my $self = shift;
    my $res  = $self->app->(@_);

    my $h = Plack::Util::headers($res->[1]);
    if (!Plack::Util::status_with_no_entity_body($res->[0]) &&
        !$h->exists('Content-Length') &&
        !$h->exists('Transfer-Encoding') &&
        defined(my $content_length = Plack::Util::content_length($res->[2]))) {
        $h->push('Content-Length' => $content_length);
    }

    return $res;
}

1;
