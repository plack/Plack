package Plack::Middleware::BufferedStreaming;
use strict;
no warnings;
use Carp;
use Plack::Util;
use Scalar::Util qw(weaken);
use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw( stream_chunked );

sub call {
    my ( $self, $env ) = @_;

    my $caller_supports_streaming = $env->{'psgi.streaming'};
    $env->{'psgi.streaming'} = Plack::Util::TRUE;

    my $res = $self->app->($env);
    if ( $self->stream_chunked ) {
        unless ( $caller_supports_streaming ) {
            die "stream_chunked was specified but server doesn't support it"
        }
    }
    elsif ( $caller_supports_streaming ) {
        return $res;
    }

    if ( ref($res) eq 'CODE' ) {
        my $ret;

        $res->(sub {
            my $write = shift;

            if ( @$write == 2 ) {
                my @body;

                return Plack::Util::inline_object(
                    write => sub { push @body, $_[0] },
                    close => sub {
                        if ($ret) {
                            $ret->([ @$write, \@body ]);
                        }
                        else {
                            $ret = [ @$write, \@body ];
                        }
                    },
                );
            } else {
                $ret = $write;
                return;
            }
        });

        if ($ret) {
            return $ret;
        }
        else {
            return sub {
                $ret = shift;
            };
        }
    } else {
        return $res;
    }
}

1;

__END__

=head1 NAME

Plack::Middleware::BufferedStreaming - Enable buffering for non-streaming aware servers

=head1 SYNOPSIS

  enable "BufferedStreaming";

=head1 DESCRIPTION

Plack::Middleware::BufferedStreaming is a PSGI middleware component
that wraps the application that uses C<psgi.streaming> interface to
run on the servers that do not support the interface, by buffering the
writer output to a temporary buffer.

If the server supports the C<psgi.streaming> interface, the middleware will be
bypassed unless the C<stream_chunked> parameter is passed. In that case, the
server must support C<psgi.streaming>, and the middleware will transform a
chunked streaming response (i.e. a streaming response where C<$writer> is
called with only code and headers) into an unchunked streaming response that
calls its C<$writer> callback with the entire response, including the
(buffered) body. This is useful if the server supports streaming responses, but
an upstream middleware (e.g. Deflater) does not support chunked responses.

=head1 AUTHOR

Yuval Kogman

Tatsuhiko Miyagawa

Adam Thomason

=cut
