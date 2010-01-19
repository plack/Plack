package Plack::Middleware::ContentLength;
use strict;
use warnings;
use parent qw( Plack::Middleware );

use Plack::Util;

sub call {
    my $self = shift;
    my $res  = $self->app->(@_);

    return $self->response_cb($res, sub {
        my $res = shift;
        my $h = Plack::Util::headers($res->[1]);
        if (!Plack::Util::status_with_no_entity_body($res->[0]) &&
            !$h->exists('Content-Length') &&
            !$h->exists('Transfer-Encoding') &&
            defined(my $content_length = Plack::Util::content_length($res->[2]))) {
            $h->push('Content-Length' => $content_length);
        }
    });
}

1;

__END__

=head1 NAME

Plack::Middleware::ContentLength - Adds Content-Length header automatically

=head1 SYNOPSIS

  # in app.psgi

  builder {
      enable "Plack::Middleware::ContentLength";
      $app;
  }

  # Or in Plack::Handler::*
  $app = Plack::Middleware::ContentLength->wrap($app);

=head1 DESCRIPTION

Plack::Middleware::ContentLength is a middleware that automatically
adds C<Content-Length> header when it's appropriate i.e. the response
has a content body with calculable size (array of chunks or a real
filehandle).

This middleware can also be used as a library from PSGI server
implementations to automatically set C<Content-Length> rather than in
the end user level.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

Rack::ContentLength

=cut

