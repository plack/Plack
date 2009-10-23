package Plack::Middleware::Deflater;
use strict;
use base qw(Plack::Middleware);

use IO::Compress::Deflate;
use IO::Compress::Gzip;
use Plack::Util;

sub call {
    my($self, $env) = @_;

    my $res = $self->app->($env);

    $self->response_cb($res, sub {
        my $res = shift;

        # do not support streaming response
        return unless defined $res->[2];

        my $h = Plack::Util::headers($res->[1]);
        if (Plack::Util::status_with_no_entity_body($res->[0]) or
            $h->get('Cache-Control') =~ /\bno-transform\b/) {
            return;
        }

        # TODO check quality
        my $encoding = 'identity';
        for my $enc (qw(deflate gzip identity)) {
            if ($env->{HTTP_ACCEPT_ENCODING} =~ /\b$enc\b/) {
                $encoding = $enc;
                last;
            }
        }

        my @vary = split /\s*,\s*/, $h->get('Vary');
        push @vary, 'Accept-Encoding';
        $h->set('Vary' => join(",", @vary));

        my $encoder;
        if ($encoding eq 'gzip') {
            $encoder = "IO::Compress::Gzip";
        } elsif ($encoding eq 'deflate') {
            $encoder = "IO::Compress::Deflate";
        } elsif ($encoding ne 'identity') {
            my $msg = "An acceptable encoding for the requested resource is not found.";
            @$res = (406, ['Content-Type' => 'text/plain'], [ $msg ]);
            return;
        }

        if ($encoder) {
            $h->set('Content-Encoding' => $encoding);
            $h->remove('Content-Length');
            my($done, $buf);
            my $compress = $encoder->new(\$buf);
            return sub {
                my $chunk = shift;
                return if $done;
                unless (defined $chunk) {
                    $done = 1;
                    $compress->flush;
                    return $buf;
                }
                $compress->print($chunk);
                if (defined $buf) {
                    my $body = $buf;
                    $buf = undef;
                    return $body;
                } else {
                    return '';
                }
            };
        }
    });
}

1;

__END__

=head1 NAME

Plack::Middleware::Deflater - Compress response body with Gzip or Deflate

=head1 SYNOPSIS

  enable "Plack::Middleware::Deflater";

=head1 DESCRIPTION

Plack::Middleware::Deflater is a middleware to encode your response
body in gzip or deflate, based on C<Accept-Encoding> HTTP request
header. It would save the bandwidth a little bit but should increase
the Plack server load, so ideally you should handle this on the
frontend reverse proxy servers.

This middleware removes C<Content-Length> and streams encoded content,
whcih means the server should support HTTP/1.1 chunked response or
downgrade to HTTP/1.0 and closes the connection.

=head1 AUTHOR

Tatsuhiko Miyagawa

=cut
