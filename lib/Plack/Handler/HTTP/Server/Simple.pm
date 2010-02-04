package Plack::Handler::HTTP::Server::Simple;
use strict;
use parent qw(HTTP::Server::Simple::PSGI);

1;

__END__

=head1 NAME

Plack::Handler::HTTP::Server::Simple - Adapter for HTTP::Server::Simple

=head1 SYNOPSIS

  plackup -s HTTP::Server::Simple --port 9090

=head1 DESCRIPTION

Plack::Handler::HTTP::Server::Simple is an adapter to run PSGI
applications on L<HTTP::Server::Simple>. This module is just a
subclass of L<HTTP::Server::Simple::PSGI> since it supports all of
L<Plack::Handler> APIs.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plack>, L<HTTP::Server::Simple::PSGI>

=cut
