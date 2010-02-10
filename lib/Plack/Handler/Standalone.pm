package Plack::Handler::Standalone;
use strict;
use warnings;
use parent qw( Plack::Handler::HTTP::Server::PSGI );

1;

__END__

=head1 NAME

Plack::Handler::Standalone - adapter for HTTP::Server::PSGI

=head1 SYNOPSIS

  % plackup -s Standalone \
      --host 127.0.0.1 --port 9091 --timeout 120

=head1 DESCRIPTION

Plack::Handler::Standalone is an adapter for default Plack server
implementation L<HTTP::Server::PSGI>. This is just an alias for
L<Plack::Handler::HTTP::Server::PSGI>.

=head1 SEE ALSO

L<Plack::Handler::HTTP::Server::PSGI>

=cut
