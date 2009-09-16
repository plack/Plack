package Plack::Impl::Danga::Socket;
use strict;
use warnings;

use Plack::Util;
use Plack::HTTPParser qw(parse_http_request);

use Danga::Socket;
use Danga::Socket::Callback;
use IO::Handle;
use IO::Socket::INET;
use HTTP::Status;
use Socket qw/IPPROTO_TCP TCP_NODELAY/;

our $HasAIO = eval {
    require IO::AIO; 1;
};

# from Perlbal
# if this is made too big, (say, 128k), then perl does malloc instead
# of using its slab cache.
use constant READ_SIZE => 61449;  # 60k, to fit in a 64k slab

use constant STATE_HEADER   => 0;
use constant STATE_BODY     => 1;
use constant STATE_RESPONSE => 2;

our $handler = [];
$handler->[STATE_HEADER]   = \&_handle_header;
$handler->[STATE_BODY]     = \&_handle_body;
$handler->[STATE_RESPONSE] = \&_handle_response;

sub new {
    my ($class, %args) = @_;

    my $self = bless {}, $class;
    $self->{host} = delete $args{host} || undef;
    $self->{port} = delete $args{port} || undef;

    $self;
}

sub run {
    my ($self, $app) = @_;

    my $ssock = IO::Socket::INET->new(
        LocalAddr => $self->{host} || '0.0.0.0',
        LocalPort => $self->{port},
        Proto     => 'tcp',
        Listen    => SOMAXCONN,
        ReuseAddr => 1,
        Blocking  => 0,
    ) or die $!;
    IO::Handle::blocking($ssock, 0);

    my ($prepared_port, $prepared_host) = unpack_sockaddr(getsockname $ssock);
    $prepared_host = format_address($prepared_host);

    Danga::Socket->AddOtherFds(fileno($ssock) => sub {
        my $csock = $ssock->accept or return;

        IO::Handle::blocking($csock, 0);
        setsockopt($csock, IPPROTO_TCP, TCP_NODELAY, pack('l', 1)) or die $!;

        my ($peer_port, $peer_host) = unpack_sockaddr(getsockname $csock);

        my $env = {
            SERVER_PORT         => $prepared_port,
            SERVER_NAME         => $prepared_host,
            SCRIPT_NAME         => '',
            'psgi.version'      => [ 1, 0 ],
            'psgi.errors'       => *STDERR,
            'psgi.url_scheme'   => 'http',
            'psgi.async'        => 1,
            'psgi.run_once'     => Plack::Util::FALSE,
            'psgi.multithread'  => Plack::Util::FALSE,
            'psgi.multiprocess' => Plack::Util::FALSE,
            REMOTE_ADDR         => format_address($peer_host),
        };

        Danga::Socket::Callback->new(
            handle        => $csock,
            context       => {
                state => STATE_HEADER,
                rbuf  => '',
                env   => $env,
                app   => $app,
            },
            on_read_ready => sub {
                my ($socket) = @_;
                $self->_next($socket);
            },
        );
    });
}

sub run_loop {
    if ($HasAIO) {
        Danga::Socket->AddOtherFds(IO::AIO::poll_fileno() => \&IO::AIO::poll_cb);
    }
    Danga::Socket->EventLoop;
}

sub _next {
    my ($self, $socket) = @_;
    $handler->[ $socket->{context}{state} ]->($self, $socket);
}

sub _handle_header {
    my ($self, $socket) = @_;

    my $bref = $socket->read(READ_SIZE);
    unless (defined $bref) {
        $socket->close;
        return;
    }
    $socket->{context}{rbuf} .= $$bref;

    my $env = $socket->{context}{env};
    my $reqlen = parse_http_request($socket->{context}{rbuf}, $env);
    if ($reqlen >= 0) {
        $socket->{context}{rbuf} = substr $socket->{context}{rbuf}, $reqlen;

        if ($env->{CONTENT_LENGTH} && $env->{REQUEST_METHOD} =~ /^(?:POST|PUT)$/) {
            $socket->{context}{state} = STATE_BODY;
        }
        else {
            $socket->{context}{state} = STATE_RESPONSE;
        }

        $self->_next($socket);
    }
    elsif ($reqlen == -2) {
        return;
    }
    elsif ($reqlen == -1) {
        $self->_start_response($socket)->(400, ['Content-Type' => 'text/plain' ]);
        $socket->write('400 Bad Request');
    }
}

sub _handle_body {
    my ($self, $socket) = @_;

    my $env = $socket->{context}{env};
    my $response_handler = $self->_response_handler($socket);

    my $bref = $socket->read(READ_SIZE);
    unless (defined $bref) {
        $socket->close;
        return;
    }
    $socket->{context}{rbuf} .= $$bref;

    if (length($socket->{context}{rbuf}) >= $env->{CONTENT_LENGTH}) {
        open my $input, '<', \$socket->{context}{rbuf};
        $env->{'psgi.input'} = $input;
        $response_handler->($socket->{context}{app}, $env);
    }
}

sub _handle_response {
    my ($self, $socket) = @_;

    my $env = $socket->{context}{env};
    my $app = $socket->{context}{app};
    my $response_handler = $self->_response_handler($socket);

    open my $input, "<", \"";
    $env->{'psgi.input'} = $input;
    $response_handler->($app, $env);

}

sub _start_response {
    my($self, $socket) = @_;

    return sub {
        my ($status, $headers) = @_;

        my $hdr;
        $hdr .= "HTTP/1.0 $status @{[ HTTP::Status::status_message($status) ]}\015\012";
        while (my ($k, $v) = splice(@$headers, 0, 2)) {
            $hdr .= "$k: $v\015\012";
        }
        $hdr .= "\015\012";

        $socket->write($hdr);

        return unless defined wantarray;
        return Plack::Util::response_handle(
            write => sub { $socket->write($_[0]) },
            close => sub { $socket->close },
        );
    };
}

sub _response_handler {
    my ($self, $socket) = @_;

    my $state_response = $self->_start_response($socket);

    Scalar::Util::weaken($socket);
    return sub {
        my ($app, $env) = @_;
        my $res = $app->($env, $state_response);
        return if scalar(@$res) == 0;

        $state_response->($res->[0], $res->[1]);

        my $body = $res->[2];

        if ($HasAIO && Plack::Util::is_real_fh($body)) {
            my $offset = 0;
            my $length = -s $body;

            my $sendfile; $sendfile = sub {
                IO::AIO::aio_sendfile($socket->{sock}, $body, $offset, $length - $offset, sub {
                    $offset += shift;
                    if ($offset >= $length) {
                        undef $sendfile;
                        $socket->close;
                    }
                    else {
                        $sendfile->();
                    }
                });
            };
            $sendfile->();
        }
        elsif (ref $body eq 'GLOB') {
            my $read = do { local $/; <$body> };
            $socket->write($read);
            $socket->close;
            $body->close;
        }
        else {
            Plack::Util::foreach( $body, sub { $socket->write($_[0]) } );
            $socket->close;
        }
    };
}

# All below codes are from AnyEvent::Socket
BEGIN {
   *sockaddr_family = $Socket::VERSION >= 1.75
      ? \&Socket::sockaddr_family
      : # for 5.6.x, we need to do something much more horrible
        (Socket::pack_sockaddr_in 0x5555, "\x55\x55\x55\x55"
           | eval { Socket::pack_sockaddr_un "U" }) =~ /^\x00/
           ? sub { unpack "xC", $_[0] }
           : sub { unpack "S" , $_[0] };
}

my $sa_un_zero = eval { Socket::pack_sockaddr_un "" }; $sa_un_zero ^= $sa_un_zero;

sub unpack_sockaddr($) {
   my $af = sockaddr_family $_[0];

   if ($af == AF_INET) {
      Socket::unpack_sockaddr_in $_[0]
   } elsif ($af == AF_INET6) {
      unpack "x2 n x4 a16", $_[0]
   } elsif ($af == AF_UNIX) {
      ((Socket::unpack_sockaddr_un $_[0] ^ $sa_un_zero), pack "S", AF_UNIX)
   } else {
      Carp::croak "unpack_sockaddr: unsupported protocol family $af";
   }
}

sub format_ipv4($) {
   join ".", unpack "C4", $_[0]
}

sub format_ipv6($) {
   if (v0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0 eq $_[0]) {
      return "::";
   } elsif (v0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1 eq $_[0]) {
      return "::1";
   } elsif (v0.0.0.0.0.0.0.0.0.0.0.0 eq substr $_[0], 0, 12) {
      # v4compatible
      return "::" . format_ipv4 substr $_[0], 12;
   } elsif (v0.0.0.0.0.0.0.0.0.0.255.255 eq substr $_[0], 0, 12) {
      # v4mapped
      return "::ffff:" . format_ipv4 substr $_[0], 12;
   } elsif (v0.0.0.0.0.0.0.0.255.255.0.0 eq substr $_[0], 0, 12) {
      # v4translated
      return "::ffff:0:" . format_ipv4 substr $_[0], 12;
   } else {
      my $ip = sprintf "%x:%x:%x:%x:%x:%x:%x:%x", unpack "n8", $_[0];

      # this is rather sucky, I admit
      $ip =~ s/^0:(?:0:)*(0$)?/::/
         or $ip =~ s/(:0){7}$/::/ or $ip =~ s/(:0){7}/:/
         or $ip =~ s/(:0){6}$/::/ or $ip =~ s/(:0){6}/:/
         or $ip =~ s/(:0){5}$/::/ or $ip =~ s/(:0){5}/:/
         or $ip =~ s/(:0){4}$/::/ or $ip =~ s/(:0){4}/:/
         or $ip =~ s/(:0){3}$/::/ or $ip =~ s/(:0){3}/:/
         or $ip =~ s/(:0){2}$/::/ or $ip =~ s/(:0){2}/:/
         or $ip =~ s/(:0){1}$/::/ or $ip =~ s/(:0){1}/:/;
      return $ip
   }
}

sub address_family($) {
   4 == length $_[0]
      ? AF_INET
      : 16 == length $_[0]
         ? AF_INET6
         : unpack "S", $_[0]
}

sub format_address($) {
   my $af = address_family $_[0];
   if ($af == AF_INET) {
      return &format_ipv4;
   } elsif ($af == AF_INET6) {
      return (v0.0.0.0.0.0.0.0.0.0.255.255 eq substr $_[0], 0, 12)
         ? format_ipv4 substr $_[0], 12
         : &format_ipv6;
   } elsif ($af == AF_UNIX) {
      return "unix/"
   } else {
      return undef
   }
}

1;

__END__


