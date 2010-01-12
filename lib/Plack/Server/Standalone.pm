package Plack::Server::Standalone;
use strict;
use warnings;

# for temporary backward compat
use parent qw( HTTP::Server::PSGI );

sub new {
    my($class, %args) = @_;

    if ($args{max_workers}) {
        require HTTP::Server::PSGI::Prefork;
        return HTTP::Server::PSGI::Prefork->new(%args);
    } else {
        return HTTP::Server::PSGI->new(%args);
    }
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

=head1 AUTHOR

Kazuho Oku

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<HTTP::Server::PSGI>

=cut
