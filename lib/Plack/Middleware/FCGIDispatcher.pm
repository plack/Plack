package Plack::Middleware::FCGIDispatcher;
use strict;
use warnings;
use base qw(Plack::Middleware);
__PACKAGE__->mk_accessors(qw(host port socket));

use FCGI::Client;
use IO::Socket::INET;
use HTTP::Response;

sub call {
    my $self = shift;
    my $env  = shift;

    # TODO: Unix socket?
    my $sock = IO::Socket::INET->new(
        PeerAddr => $self->host || '127.0.0.1',
        PeerPort => $self->port,
    ) or die $!;

    my $conn = FCGI::Client::Connection->new(sock => $sock);
    my $input = delete $env->{'psgi.input'};
    my $content_in = do { local $/; <$input> };
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

Plack::Middleware::FCGIDispatcher - Dispatch requests to FCGI servers

=head1 SYNOPSIS

  # app.psgi
  use Plack::Middleware::FCGIDispatcher;
  my $app = Plack::Middleware::FCGIDispatcher->new({
      port => 8080, # FastCGI daemon port
  })->to_app;

=head1 DESCRIPTION

Plack::Middleware::FCGIDispatcher is not really a middleware but it's
a PSGI application to dispatch requests to external FCGI servers.

=head1 AUTHOR

Tokuhiro Matsuno

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<FCGI::Client>

=cut
