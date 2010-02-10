package Plack::Handler::HTTP::Server::Simple;
use strict;

sub new {
    my($class, %args) = @_;
    bless {%args}, $class;
}

sub run {
    my($self, $app) = @_;

    my $server = Plack::Handler::HTTP::Server::Simple::PSGIServer->new($self->{port});
    $server->host($self->{host}) if $self->{host};
    $server->app($app);
    $server->{_server_ready} = delete $self->{server_ready} || sub {};

    $server->run;
}

package Plack::Handler::HTTP::Server::Simple::PSGIServer;
use parent qw(HTTP::Server::Simple::PSGI);

sub print_banner {
    my $self = shift;

    $self->{_server_ready}->({
        host => $self->host,
        port => $self->port,
        server_software => 'HTTP::Server::Simple::PSGI',
    });
}

package Plack::Handler::HTTP::Server::Simple;

1;

__END__

=head1 NAME

Plack::Handler::HTTP::Server::Simple - Adapter for HTTP::Server::Simple

=head1 SYNOPSIS

  plackup -s HTTP::Server::Simple --port 9090

=head1 DESCRIPTION

Plack::Handler::HTTP::Server::Simple is an adapter to run PSGI
applications on L<HTTP::Server::Simple>.

=head1 SEE ALSO

L<Plack>, L<HTTP::Server::Simple::PSGI>

=head1 AUTHOR

Tatsuhiko Miyagawa


=cut
