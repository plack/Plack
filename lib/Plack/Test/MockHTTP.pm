package Plack::Test::MockHTTP;
use strict;
use warnings;

use base qw(Exporter);
our @EXPORT = qw(test_mock_http);

use Carp;
use HTTP::Request;
use HTTP::Response;
use HTTP::Request::AsCGI;
use Plack::Server::CGI;

sub test_mock_http {
    my %args = @_;

    my $client = delete $args{client} or croak "client test code needed";
    my $app    = delete $args{app}    or croak "app needed";

    my $cb = sub {
        my $req = shift;
        my $c   = HTTP::Request::AsCGI->new($req)->setup;
        eval { Plack::Server::CGI->new->run($app) };
        return $c->response;
    };

    $client->($cb);
}

1;

__END__

=head1 NAME

Plack::Test::MockHTTP - Run mocked HTTP tests through PSGI applications

=head1 SYNOPSIS

  use Plack::Test::MockHTTP;

  test_mock_http
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

Plack::Test::MockHTTP is an utility to run PSGI application given
HTTP::Request objects and return HTTP::Response object out of PSGI
application response.

See also L<Plack::Test::Server> that gives you the same interface but
runs the HTTP::Request live through Plack server backends.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plack::Test::Server>

=cut


