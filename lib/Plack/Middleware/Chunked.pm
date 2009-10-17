package Plack::Middleware::Chunked;
use strict;
use base qw(Plack::Middleware);

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
            ! $h->exists('Transfer-Encoding') and
            defined $res->[2]
        ) {
            $h->set('Transfer-Encoding' => 'chunked');
            my $body    = $res->[2];
            my $getline = ref $body eq 'ARRAY' ? sub { shift @$body } : { $body->getline };
            my $done;
            $res->[2] = Plack::Util::inline_object
                getline => sub {
                    my $chunk = $getline->();
                    return if $done;
                    unless (defined $chunk) {
                        $done = 1;
                        return "0\015\012\015\012";
                    }
                    return '' unless length $chunk;
                    return sprintf('%x', length $chunk) . "\015\012$chunk\015\012";
                },
                close => sub { $body->close if ref $body ne 'ARRAY' };
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
