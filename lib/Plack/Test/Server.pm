package Plack::Test::Server;
use strict;
use warnings;
use Carp;
use LWP::UserAgent;
use Test::TCP;
use Plack::Loader;

use base qw(Exporter);
our @EXPORT = qw( test_server );

sub test_server {
    my %args = @_;

    my $client = delete $args{client} or croak "client test code needed";
    my $app    = delete $args{app}    or croak "app needed";
    my $ua     = delete $args{ua} || LWP::UserAgent->new;

    test_tcp(
        client => sub {
            my $port = shift;
            my $cb = sub {
                my $req = shift;
                $req->uri->host($args{host} || '127.0.0.1');
                $req->uri->port($port);
                return $ua->request($req);
            };
            $client->($cb);
        },
        server => sub {
            my $port = shift;
            my $server = Plack::Loader->auto(port => $port, host => ($args{host} || '127.0.0.1'));
            $server->run($app);
            $server->run_loop if $server->can('run_loop');
        },
    );
}

1;

__END__

=head1 NAME

Plack::Test::Server - Run HTTP tests through live Plack servers

=head1 SYNOPSIS

  use Plack::Test::Server;

  test_server
      client => sub {
          my $cb = shift;
          my $req = HTTP::Request->new(GET => "http://localhost/hello");
          my $res = $cb->($req);
          like $res->content, qr/Hello World/;
      },
      app => sub {
          my $env = shift;
          return [ 200, [ 'Content-Type' => 'text/plain' ], [ "Hello World" ] ];
      };

=head1 DESCRIPTION

Plack::Test::Server is an utility to run PSGI application with Plack
server implementations, and run the live HTTP tests with the server
using a callback.

The server backend is chosen using with C<PLACK_SERVER> environment
variables and alike. See L<Plack::Loader> for details.

See also L<Plack::Test::MockHTTP> that gives you the same interface
but runs the HTTP::Request natively in the PSGI app without an actual
HTTP server.

=head1 AUTHOR

Tatsuhiko Miyagawa

Tokuhiro Matsuno

=head1 SEE ALSO

L<Plack::Loader> L<Test::TCP> L<Plack::Test::MockHTTP> L<Plack::Test::Server::Suite>

=cut

