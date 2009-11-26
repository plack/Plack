package Plack::Middleware::Chunked;
use strict;
use parent qw(Plack::Middleware);

use Plack::Util;

sub call {
    my($self, $env) = @_;
    my $res = $self->app->($env);
    $self->response_cb($res, sub {
        my $res = shift;
        my $h = Plack::Util::headers($res->[1]);
        if ($env->{'SERVER_PROTOCOL'} ne 'HTTP/1.0' and
            ! Plack::Util::status_with_no_entity_body($res->[0]) and
            ! $h->exists('Content-Length') and
            ! $h->exists('Transfer-Encoding')
        ) {
            $h->set('Transfer-Encoding' => 'chunked');
            my $done;
            return sub {
                my $chunk = shift;
                return if $done;
                unless (defined $chunk) {
                    $done = 1;
                    return "0\015\012\015\012";
                }
                return '' unless length $chunk;
                return sprintf('%x', length $chunk) . "\015\012$chunk\015\012";
            };
        }
    });
}

1;

__END__

=head1 NAME

Plack::Middleware::Chunked - Applies chunked encoding to the response body

=head1 SYNOPSIS

  # Mostly from server implemenations
  $app = Plack::Middeware::Chunked->wrap($app);

=head1 DESCRIPTION

Plack::Middeware::Chunked is a middleware, or rather a library for
PSGI server to automatically add chunked encoding to the response body
when Content-Length is not set in the response header.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

Rack::Chunked

=cut
