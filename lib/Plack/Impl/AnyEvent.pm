package Plack::Impl::AnyEvent;
use strict;
use warnings;

use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;
use Plack::Util;
use HTTP::Status;
use Plack::HTTPParser qw(parse_http_request);
use IO::Handle;
use Errno ();

sub new {
    my($class, %args) = @_;

    my $self = bless {}, $class;
    $self->{host} = delete $args{host} || undef;
    $self->{port} = delete $args{port} || undef;

    $self;
}

sub run {
    my($self, $app) = @_;

    my $guard = tcp_server $self->{host}, $self->{port}, sub {

        my ( $sock, $peer_host, $peer_port ) = @_;

        if ( !$sock ) {
            return;
        }

        my $env = {
            SERVER_PORT       => $self->{prepared_port},
            SERVER_NAME       => $self->{prepared_host},
            SCRIPT_NAME       => '',
            'psgi.version'    => [ 1, 0 ],
            'psgi.errors'     => *STDERR,
            'psgi.url_scheme' => 'http',
            'psgi.async'      => 1,
            'psgi.run_once'     => Plack::Util::FALSE,
            'psgi.multithread'  => Plack::Util::FALSE,
            'psgi.multiprocess' => Plack::Util::FALSE,
            REMOTE_ADDR       => $peer_host,
        };

        # Note: broken pipe in test is maked by Test::TCP.
        my $handle;
        $handle = AnyEvent::Handle->new(
            fh       => $sock,
            timeout  => 3,
            on_eof   => sub { undef $handle; undef $env; },
            on_error => sub { undef $handle; undef $env; warn $! if $! != Errno::EPIPE },
            on_timeout => sub { undef $handle; undef $env; },
        );

        my $parse_header;
        my $buf = '';
        $parse_header = sub {
            my ( $handle, $chunk ) = @_;
            $buf .= $chunk . "\r\n";
            my $reqlen = parse_http_request($buf, $env);
            if ($reqlen == -2) {
                $handle->push_read( line => $parse_header );
            } elsif ($reqlen == -1) {
                $self->_start_response($handle)->(400, [ 'Content-Type' => 'text/plain' ]);
                $handle->push_write("400 Bad Request");
            } elsif ($reqlen > 0) {
                my $response_handler = $self->_response_handler($handle);
                if ($env->{CONTENT_LENGTH} && $env->{REQUEST_METHOD} =~ /^(?:POST|PUT)$/) {
                    # Slurp content
                    $handle->push_read(
                        chunk => $env->{CONTENT_LENGTH}, sub {
                            my ($handle, $data) = @_;
                            open my $input, "<", \$data;
                            $env->{'psgi.input'} = $input;
                            $response_handler->($app, $env);
                        }
                    );
                } else {
                    my $data = '';
                    open my $input, "<", \$data;
                    $env->{'psgi.input'} = $input;
                    $response_handler->($app, $env);
                }
            }
            else {
                $handle->push_read( line => $parse_header );
            }
          };

        $handle->push_read( line => $parse_header );
        return;
      }, sub {
        my ( $fh, $host, $port ) = @_;
        $self->{prepared_host} = $host;
        $self->{prepared_port} = $port;
        warn "Accepting requests at http://$host:$port/\n";
        return 0;
      };
    $self->{listen_guard} = $guard;
}

sub _start_response {
    my($self, $handle) = @_;

    return sub {
        my ($status, $headers) = @_;
        $handle->push_write("HTTP/1.0 $status @{[ HTTP::Status::status_message($status) ]}\r\n");
        while (my ($k, $v) = splice(@$headers, 0, 2)) {
            $handle->push_write("$k: $v\r\n");
        }
        $handle->push_write("\r\n");
        return Plack::Util::response_handle(
            write => sub { $handle->push_write($_[0]) },
            close => sub { $handle->push_shutdown },
        );
    };
}

sub _response_handler {
    my($self, $handle) = @_;

    my $start_response = $self->_start_response($handle);

    return sub {
        my($app, $env) = @_;
        my $res = $app->($env, $start_response);
        return if scalar(@$res) == 0;

        $start_response->($res->[0], $res->[1]);

        my $body = $res->[2];
        if ( ref $body eq 'GLOB') {
            my $read; $read = sub {
                my $w; $w = AnyEvent->io(
                    fh => $body,
                    poll => 'r',
                    cb => sub {
                        $body->read(my $buf, 4096);
                        $handle->push_write($buf);
                        if ($body->eof) {
                            undef $w;
                            $body->close;
                            $handle->on_drain(sub {
                                $handle->destroy;
                            });
                        } else {
                            $read->();
                        }
                    },
                );
            };
            $read->();
        } else {
            my $cb = sub { $handle->push_write($_[0]) };
            Plack::Util::foreach( $body, $cb );
            $handle->push_shutdown();
        }
    };
}

sub run_loop {
    AnyEvent->condvar->recv;
}

1;
__END__

# note: regexps taken from HSS

=head1 NAME

Plack::Impl::AnyEvent - AnyEvent based HTTP server

=head1 SYNOPSIS

  my $server = Plack::Impl::AnyEvent->new(
      host => $host,
      port => $port,
  );
  $server->run($app);

=head1 DESCRIPTION

This implementation is considered highly experimental.

=cut
