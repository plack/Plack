package Plack::Test;
use strict;
use warnings;
use parent qw(Exporter);
our @EXPORT = qw(test_psgi);

our $Impl;
$Impl ||= $ENV{PLACK_TEST_IMPL} || "MockHTTP";

sub test_psgi {
    eval "require Plack::Test::$Impl;";
    die $@ if $@;
    no strict 'refs';
    if (@_ == 2) {
        @_ = (app => $_[0], client => $_[1]);
    }
    &{"Plack::Test::$Impl\::test_psgi"}(@_);
}

1;

__END__

=head1 NAME

Plack::Test - Test PSGI applications with various backends

=head1 SYNOPSIS

  use Plack::Test;

  # named params
  test_psgi
      app => sub {
          my $env = shift;
          return [ 200, [ 'Content-Type' => 'text/plain' ], [ "Hello World" ] ],
      },
      client => sub {
          my $cb = shift;
          my $req = HTTP::Request->new(GET => "http://localhost/hello");
          my $res = $cb->($req);
          like $res->content, qr/Hello World/;
      };

   use HTTP::Request::Common;

   # positional params (app, client)
   my $app = sub { return [ 200, [], [ "Hello "] ] };
   test_psgi $app, sub {
       my $cb = shift;
       my $res = $cb->(GET "/");
       is $res->content, "Hello";
   };


=head1 DESCRIPTION

Plack::Test is an unified interface to test PSGI applications using
standard HTTP::Request and HTTP::Response objects. It also allows you
to run PSGI applications in various ways, by default using C<MockHTTP>
backend but can also use C<Server> backend, which uses one of
L<Plack::Server> implementations to run the web server to do live HTTP
requests.

=head1 FUNCTIONS

=over 4

=item test_psgi

  test_psgi $app, $client;
  test_psgi app => $app, client => $client;

Runs the client test code C<$client> against a PSGI application
C<$app>. The client callback gets one argument C<$cb>, that is a
callback that accepts an HTTP::Request object and returns an
HTTP::Response object.

For the convenience, HTTP::Request given to the callback is
automatically adjusted to the correct protocol (I<http>) and host
names (I<127.0.0.1> by default), so the following code just works.

  use HTTP::Request::Common;
  test_psgi $app, sub {
      my $cb = shift;
      my $res = $cb->(GET "/hello");
  };

=back

=head1 OPTIONS

You can specify the L<Plack::Test> backend using the environment
variable C<PLACK_TEST_IMPL> or C<$Plack::Test::Impl> package variable.

The available values for the backend are:

=over 4

=item MockHTTP

(Default) Creates a PSGI env hash out of HTTP::Request object, runs
the PSGI application in-process and returns HTTP::Response.

=item Server

Runs one of Plack::Server backends (C<Standalone> by default) and
sends live HTTP requests to test.

=back

For instance, you can test your application with C<ServerSimple> server backends with:

  > env PLACK_TEST_IMPL=Server PLACK_SERVER=ServerSimple prove -l t/test.t

=head1 AUTHOR

Tatsuhiko Miyagawa

=cut
