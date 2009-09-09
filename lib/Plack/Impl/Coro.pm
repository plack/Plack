package Plack::Impl::Coro;
use strict;
use Coro;
use Coro::Semaphore;
use Coro::Event;
use Coro::Socket;
use HTTP::Status;

no utf8;
use bytes;

our $MAX_CONNECTS = 500;			# maximum simult. connects
our $REQ_TIMEOUT  =  60;			# request timeout
our $RES_TIMEOUT  = 180;			# response timeout
our $MAX_POOL     =  20;			# max. number of idle workers

sub new {
    my($class, %args) = @_;
    bless \%args, $class;
}

sub run {
    my($self, $app) = @_;

    my $port = new Coro::Socket
        LocalAddr => $self->{host},
        LocalPort => $self->{port},
        ReuseAddr => 1,
        Listen => 1,
            or die "unable to start server";

    $SIG{PIPE} = 'IGNORE';

    my $connections = new Coro::Semaphore $MAX_CONNECTS;

    my @fh;

    # move the event main loop into a coroutine
    async { loop };

    warn "accepting connections http://$self->{host}:$self->{port}/";

    while () {
        $connections->down;
        if (my $fh = $port->accept) {
#            warn "accepted @$connections ".scalar(@pool);
            async_pool {
                eval {
                    conn->new($fh)->handle($app);
                };
                close $fh;
                warn "$@" if $@ && !ref $@;
                $connections->up;
            };
        }
    }
}

package conn;

use Socket;
use HTTP::Date;

sub new {
   my $class = shift;
   my $fh = shift;
   my (undef, $iaddr) = unpack_sockaddr_in $fh->peername
      or $class->err(500, "unable to get peername");
   my $self = bless { fh => $fh }, $class;
   $self->{remote_address} = inet_ntoa $iaddr;
   $self;
}

sub print_response {
   my ($self, $code, $msg, $hdr, $content) = @_;
   my $res = "HTTP/1.0 $code $msg\015\012";

   $hdr->{Date} = time2str time; # slow? nah.

   while (my ($h, $v) = each %$hdr) {
      $res .= "$h: $v\015\012"
   }
   $res .= "\015\012$content" if defined $content;

   print {$self->{fh}} $res;
}

sub err {
   my $self = shift;
   my ($code, $msg, $hdr, $content) = @_;

   unless (defined $content) {
      $content = "$code $msg";
      $hdr->{"Content-Type"} = "text/plain";
      $hdr->{"Content-Length"} = length $content;
   }

   warn $msg if $code;

   $self->print_response($code, $msg, $hdr, $content);

   die bless {}, err::;
}

sub handle {
   my($self, $app) = @_;

   my $fh = $self->{fh};

   $self->{h} = {};

   # read request and parse first line
   $fh->timeout($::REQ_TIMEOUT);
   my $req = $fh->readline("\015\012\015\012");
   $fh->timeout($::RES_TIMEOUT);

   defined $req or
       $self->err(408, "request timeout");

   $req =~ /^(?:\015\012)?
            (GET|HEAD|POST|PUT) \040+
            ([^\040]+) \040+
            HTTP\/([0-9]+\.[0-9]+)
            \015\012/gx
        or $self->err(405, "method not allowed", { Allow => "GET,HEAD,POST,PUT" });

   $2 < 2
       or $self->err(506, "http protocol version not supported");

   $self->{method} = $1;
   $self->{uri} = $2;
   $self->{protocol} = $3;

   # parse headers
   {
       my (%hdr, $h, $v);

       $hdr{lc $1} .= ",$2"
           while $req =~ /\G
              ([^:\000-\040]+):
              [\011\040]*
              ((?: [^\015\012]+ | \015\012[\011\040] )*)
              \015\012
           /gxc;

       $req =~ /\G\015\012$/
           or $self->err(400, "bad request");

       $self->{h}{$h} = substr $v, 1
           while ($h, $v) = each %hdr;
   }

   $self->{server_port} = $self->{h}{host} =~ s/:([0-9]+)$// ? $1 : 80;

   my ( $path, $query_string )
       = ( $self->{uri} =~ /([^?]*)(?:\?(.*))?/s );

   my $env = {};
   $env->{REQUEST_METHOD} = $self->{method};
   $env->{SCRIPT_NAME}    = '';
   $env->{PATH_INFO}      = $path;
   $env->{QUERY_STRING}   = $query_string || '';
   $env->{HTTP_HOST}      = $self->server_host;
   $env->{SERVER_NAME}    = ($self->server_address)[0];
   $env->{SERVER_PORT}    = $self->{server_port};
   $env->{SERVER_PROTOCOL} = "HTTP/$self->{protocol}";
   $env->{REMOTE_ADDR}    = $self->{remote_address};

   while (my($k, $v) = each %{$self->{h}}) {
       my ($k, $v) = ($1,$2);
       $k =~ s/-/_/;
       $k = uc $k;
       if ($k !~ /^(?:CONTENT_LENGTH|CONTENT_TYPE)$/i) {
           $k = "HTTP_$k";
       }
       $env->{ $k } = $v;
   }

   $env->{'psgi.version'} = [ 1, 0 ];
   $env->{'psgi.url_scheme'} = 'http';
   $env->{'psgi.errors'}  = *STDERR;
   $env->{'psgi.input'}   = $self->{fh};

   my $r = $app->($env);

   my $msg = HTTP::Status::status_message($r->[0]);
   $self->{fh}->print("HTTP/1.0 $r->[0] $msg\015\012");

   my $hdr = $r->[1];
   push @$hdr, Date => time2str time; # slow? nah.

   while (my ($h, $v) = splice @$hdr) {
       $self->{fh}->print("$h: $v\015\012")
   }
   $self->{fh}->print("\015\012");

   if (ref $r->[2] eq 'ARRAY') {
       $self->{fh}->print(@{$r->[2]});
   } else {
       -r $r->[2]; # assume it's a real file
       $self->handle_file;
   }
}

sub server_address {
   my $self = shift;
   my ($port, $iaddr) = unpack_sockaddr_in $self->{fh}->sockname
      or $self->err(500, "unable to get socket name");
   ((inet_ntoa $iaddr), $port);
}

sub server_host {
   my $self = shift;
   if (exists $self->{h}{host}) {
      return $self->{h}{host};
   } else {
      return (($self->server_address)[0]);
   }
}

sub server_hostport {
   my $self = shift;
   my ($host, $port);
   if (exists $self->{h}{host}) {
      ($host, $port) = ($self->{h}{host}, $self->{server_port});
   } else {
      ($host, $port) = $self->server_address;
   }
   $port = $port == 80 ? "" : ":$port";
   $host.$port;
}

sub handle_file {
   my $self = shift;
   my $length = -s _;
   my $hdr = {
      "Last-Modified"  => time2str ((stat _)[9]),
   };

   my @code = (200, "ok");
   my ($l, $h);

   if ($self->{h}{range} =~ /^bytes=(.*)$/i) {
      for (split /,/, $1) {
         if (/^-(\d+)$/) {
            ($l, $h) = ($length - $1, $length - 1);
         } elsif (/^(\d+)-(\d*)$/) {
            ($l, $h) = ($1, ($2 ne "" || $2 >= $length) ? $2 : $length - 1);
         } else {
            ($l, $h) = (0, $length - 1);
            goto ignore;
         }
         goto satisfiable if $l >= 0 && $l < $length && $h >= 0 && $h >= $l;
      }
      $hdr->{"Content-Range"} = "bytes */$length";
      $self->err(416, "not satisfiable", $hdr);

satisfiable:
      $hdr->{"Content-Range"} = "bytes $l-$h/$length";
      @code = (206, "partial content");
      $length = $h - $l + 1;

ignore:
   } else {
      ($l, $h) = (0, $length - 1);
   }

   if ($self->{path} =~ /\.html$/) {
      $hdr->{"Content-Type"} = "text/html";
   } else {
      $hdr->{"Content-Type"} = "application/octet-stream";
   }

   $hdr->{"Content-Length"} = $length;

   $self->print_response(@code, $hdr, "");

   if ($self->{method} eq "GET") {
      my ($fh, $buf);
      open $fh, "<", $self->{path}
         or die "$self->{path}: late open failure ($!)";

      if ($l) {
         sysseek $fh, $l, 0
            or die "$self->{path}: cannot seek to $l ($!)";
      }

      $h -= $l - 1;

      while ($h > 0) {
         $h -= sysread $fh, $buf, $h > 4096 ? 4096 : $h;
         print {$self->{fh}} $buf
            or last;
      }

      close $fh;
  }
}

__END__

=head1 NAME

Plack::Impl::Coro - Coro's myhttpd based implementation

=head1 DESCRIPTION

This code is based on C<myhttpd> included in L<Coro>'s distribution, copyright Mark Lehmann. Considered highly experimental.

=cut



