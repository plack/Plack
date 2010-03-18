package Plack::App::FCGIDispatcher;
use strict;
use warnings;
use parent qw(Plack::Component);
use Plack::Util::Accessor qw(host port socket);

use FCGI::Client;
use HTTP::Response;

sub call {
    my $self = shift;
    my $env  = shift;

    my $sock;
    if ($self->socket) {
        require IO::Socket::UNIX;
        $sock = IO::Socket::UNIX->new(
            Peer => $self->socket,
        );
    } elsif ($self->port) {
        require IO::Socket::INET;
        $sock = IO::Socket::INET->new(
            PeerAddr => $self->host || '127.0.0.1',
            PeerPort => $self->port,
        );
    } else {
        die "FCGI daemon host/port or socket is not specified";
    }

    $sock or die "Can't create socket to FCGI daemon: $!";

    my $conn = FCGI::Client::Connection->new(sock => $sock);
    my $input = delete $env->{'psgi.input'};

    my $content_in = '';
    if (my $cl = $env->{CONTENT_LENGTH}) {
        while ($cl > 0) {
            my $read = $input->read($content_in, $cl, length $content_in);
            $cl -= $read;
        }
    }

    for my $key (keys %$env) {
        delete $env->{$key} if $key =~ /\./;
    }

    my ($stdout, $stderr) = $conn->request(
        $env,
        $content_in,
    );
    print STDERR $stderr if $stderr;

    unless ( $stdout =~ /^HTTP/ ) {
        $stdout = "HTTP/1.1 200 OK\015\012" . $stdout;
    }

    ($stdout =~ /^(.+?\015?\012\015?\012)(.*)$/s) or die "No header/body separator";
    my ($header_part, $content) = ($1, $2);

    my $res = HTTP::Response->parse($header_part);
    if ($res->content) {
        # we passed only headers but has body: Bad headers
        return [ 500, [ 'Content-Type' => 'text/plain' ], [ 'Bad HTTP headers returned' ] ];
    }

    my $status = $res->header('Status') || 200;
       $status =~ s/\s+.*$//; # remove ' OK' in '200 OK'

    my $headers = [
        map {
            my $k = $_;
            map { ( $k => $_ ) } $res->headers->header($_);
        } $res->headers->header_field_names
    ];

    return [ $status, $headers, [ $content ] ];
}

1;

__END__

=head1 NAME

Plack::App::FCGIDispatcher - Dispatch requests to FCGI servers

=head1 SYNOPSIS

  # app.psgi
  use Plack::App::FCGIDispatcher;
  my $app = Plack::App::FCGIDispatcher->new({
      port => 8080, # FastCGI daemon port
  })->to_app;

=head1 DESCRIPTION

Plack::App::FCGIDispatcher is not really a middleware but it's
a PSGI application to dispatch requests to external FCGI servers.

=head1 CONFIGURATION

=over 4

=item host, port

  my $app = Plack::App::FCGIDispatcher->new({
      host => '127.0.0.1', port => 8080,
  })->to_app;

Specifies host and port where FastCGI daemon is listening. host defaults to C<127.0.0.1>.

=item socket

  my $app = Plack::App::FCGIDispatcher->new({
      socket => "/tmp/fcgi.sock",
  })->to_app;

Specifies UNIX socket path where FastCGI daemon is listening.

=back

=head1 AUTHOR

Tokuhiro Matsuno

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<FCGI::Client>

=cut
