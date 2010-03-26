package Plack::Handler::HTTP::Server::PSGI;
use strict;

# for temporary backward compat
use parent qw( HTTP::Server::PSGI );

sub new {
    my($class, %args) = @_;
    bless { %args }, $class;
}

sub run {
    my($self, $app) = @_;
    $self->_server->run($app);
}

sub _server {
    my $self = shift;
    HTTP::Server::PSGI->new(%$self);
}

1;

__END__

=head1 NAME

Plack::Handler::HTTP::Server::PSGI - adapter for HTTP::Server::PSGI

=head1 SYNOPSIS

  % plackup -s HTTP::Server::PSGI \
      --host 127.0.0.1 --port 9091 --timeout 120

=head1 BACKWARD COMPATIBLITY

Since Plack 0.99_22 this handler doesn't support preforking
configuration i.e. C<--max-workers>. Use L<Starman> or L<Starlet> if
you need preforking PSGI web server.

=head1 CONFIGURATIONS

=over 4

=item host

Host the server binds to. Defaults to all interfaces.

=item port

Port number the server listens on. Defaults to 8080.

=item timeout

Number of seconds a request times out. Defaults to 300.

=item max-reqs-per-child

Number of requests per worker to process. Defaults to 100.

=back

=head1 AUTHOR

Kazuho Oku

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plack> L<HTTP::Server::PSGI>

=cut
