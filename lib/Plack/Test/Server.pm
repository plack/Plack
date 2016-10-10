package Plack::Test::Server;
use strict;
use warnings;
use Carp;
use HTTP::Request;
use HTTP::Response;
use Test::TCP;
use Plack::Loader;
use Plack::LWPish;

sub new {
    my($class, $app, %args) = @_;

    my $host = $args{host} || '127.0.0.1';
    my $server = Test::TCP->new(
        listen => $args{listen},
        host => $host,
        code => sub {
            my $sock_or_port = shift;
            my $server = Plack::Loader->auto(
                ($args{listen} ? (
                    listen_sock => $sock_or_port,
                ):(
                    port => $sock_or_port,
                    host => $host,
                ))
            );
            $server->run($app);
            exit;
        },
    );

    bless { server => $server, %args }, $class;
}

sub port {
    my $self = shift;
    $self->{server}->port;
}

sub request {
    my($self, $req) = @_;

    my $ua = $self->{ua} || Plack::LWPish->new( no_proxy => [qw/127.0.0.1/] );

    $req->uri->scheme('http');
    $req->uri->host($self->{host} || '127.0.0.1');
    $req->uri->port($self->port);

    return $ua->request($req);
}

1;

__END__

=head1 NAME

Plack::Test::Server - Run HTTP tests through live Plack servers

=head1 DESCRIPTION

Plack::Test::Server is a utility to run PSGI application with Plack
server implementations, and run the live HTTP tests with the server
using a callback. See L<Plack::Test> how to use this module.

=head1 AUTHOR

Tatsuhiko Miyagawa

Tokuhiro Matsuno

=head1 SEE ALSO

L<Plack::Loader> L<Test::TCP> L<Plack::Test>

=cut

