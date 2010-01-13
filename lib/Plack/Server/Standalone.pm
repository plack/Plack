package Plack::Server::Standalone;
use strict;
use warnings;

# for temporary backward compat
use parent qw( HTTP::Server::PSGI );

sub new {
    my($class, %args) = @_;
    HTTP::Server::PSGI->new(%args);
}

1;

__END__

=head1 NAME

Plack::Server::Standalone - adapters for HTTP::Server::PSGI

=head1 SYNOPSIS

  % plackup -s Standalone \
      --host 127.0.0.1 --port 9091 --timeout 120

=head1 DESCRIPTION

Plack::Server::Standalone is an adapter for default Plack server
implementation L<HTTP::Server::PSGI>.

=head1 CONFIGURATIONS

This adapter automatically loads Prefork implementation when
C<max-workers> is set, but otherwise the default HTTP::Server::PSGI
which is single process.

=over 4

=item host

Host the server binds to. Defaults to all interfaces.

=item port

Port number the server listens on. Defaults to 8080.

=item timeout

Number of seconds a request times out. Defaults to 300.

=item max-keepalive-reqs

Max requests per a keep-alive request. Defaults to 1, which means Keep-alive is off.

=item keepalive-timeout

Number of seconds a keep-alive request times out. Defaults to 2.

=item max-workers

Number of prefork workers. Defaults to 10.

=item max-reqs-per-child

Number of requests per worker to process. Defaults to 100.

=item max-keepalive-reqs

Max requests per a keep-alive request. Defaults to 100.

=back

=head1 AUTHOR

Kazuho Oku

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<HTTP::Server::PSGI>

=cut
