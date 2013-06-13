package Plack::Test::Server;
use strict;
use warnings;
use Carp;
use HTTP::Request;
use HTTP::Response;
use Test::TCP;
use Plack::Loader;
use Plack::LWPish;

sub test_psgi {
    my %args = @_;

    my $client = delete $args{client} or croak "client test code needed";
    my $app    = delete $args{app}    or croak "app needed";
    my $ua     = delete $args{ua} || Plack::LWPish->new;

    test_tcp(
        client => sub {
            my $port = shift;
            my $cb = sub {
                my $req = shift;
                $req->uri->scheme('http');
                $req->uri->host($args{host} || '127.0.0.1');
                $req->uri->port($port);
                return $ua->request($req);
            };
            $client->($cb);
        },
        server => $args{server} || sub {
            my $port = shift;
            my $server = Plack::Loader->auto(port => $port, host => ($args{host} || '127.0.0.1'));
            $server->run($app);
            exit;
        },
    );
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

