package Plack::Test;
use strict;
use warnings;
use Carp;
use parent qw(Exporter);
our @EXPORT = qw(test_psgi);

our $Impl;
$Impl ||= $ENV{PLACK_TEST_IMPL} || "MockHTTP";

sub create {
    my($class, $app, @args) = @_;

    my $subclass = "Plack::Test::$Impl";
    eval "require $subclass";
    die $@ if $@;

    no strict 'refs';
    if (defined &{"Plack::Test::$Impl\::test_psgi"}) {
        return \&{"Plack::Test::$Impl\::test_psgi"};
    }

    $subclass->new($app, @args);
}

sub test_psgi {
    if (ref $_[0] && @_ == 2) {
        @_ = (app => $_[0], client => $_[1]);
    }
    my %args = @_;

    my $app    = delete $args{app}; # Backward compat: some implementations don't need app
    my $client = delete $args{client} or Carp::croak "client test code needed";

    my $tester = Plack::Test->create($app, %args);
    return $tester->(@_) if ref $tester eq 'CODE'; # compatibility

    $client->(sub { $tester->request(@_) });
}

1;

__END__

=head1 NAME

Plack::Test - Test PSGI applications with various backends

=head1 SYNOPSIS

  use Plack::Test;
  use HTTP::Request::Common;

  # Simple OO interface
  my $app = sub { return [ 200, [], [ "Hello" ] ] };
  my $test = Plack::Test->create($app);

  my $res = $test->request(GET "/");
  is $res->content, "Hello";

  # traditional - named params
  test_psgi
      app => sub {
          my $env = shift;
          return [ 200, [ 'Content-Type' => 'text/plain' ], [ "Hello World" ] ],
      },
      client => sub {
          my $cb  = shift;
          my $req = HTTP::Request->new(GET => "http://localhost/hello");
          my $res = $cb->($req);
          like $res->content, qr/Hello World/;
      };

  # positional params (app, client)
  my $app = sub { return [ 200, [], [ "Hello" ] ] };
  test_psgi $app, sub {
      my $cb  = shift;
      my $res = $cb->(GET "/");
      is $res->content, "Hello";
  };

=head1 DESCRIPTION

Plack::Test is a unified interface to test PSGI applications using
L<HTTP::Request> and L<HTTP::Response> objects. It also allows you to run PSGI
applications in various ways. The default backend is C<Plack::Test::MockHTTP>,
but you may also use any L<Plack::Handler> implementation to run live HTTP
requests against a web server.

=head1 METHODS

=over 4

=item create

  $test = Plack::Test->create($app, %options);

creates an instance of Plack::Test implementation class. C<$app> has
to be a valid PSGI application code reference.

=item request

  $res = $test->request($request);

takes an HTTP::Request object, runs it through the PSGI application to
test and returns an HTTP::Response object.

=back

=head1 FUNCTIONS

Plack::Test also provides a functional interface that takes two
callbacks, each of which represents PSGI application and HTTP client
code that tests the application.

=over 4

=item test_psgi

  test_psgi $app, $client;
  test_psgi app => $app, client => $client;

Runs the client test code C<$client> against a PSGI application
C<$app>. The client callback gets one argument C<$cb>, a
callback that accepts an C<HTTP::Request> object and returns an
C<HTTP::Response> object.

Use L<HTTP::Request::Common> to import shortcuts for creating requests for
C<GET>, C<POST>, C<DELETE>, and C<PUT> operations.

For your convenience, the C<HTTP::Request> given to the callback automatically
uses the HTTP protocol and the localhost (I<127.0.0.1> by default), so the
following code just works:

  use HTTP::Request::Common;
  test_psgi $app, sub {
      my $cb  = shift;
      my $res = $cb->(GET "/hello");
  };

Note that however, it is not a good idea to pass an arbitrary
(i.e. user-input) string to C<GET> or even C<<
HTTP::Request->new >> by assuming that it always represents a path,
because:

  my $req = GET "//foo/bar";

would represent a request for a URL that has no scheme, has a hostname
I<foo> and a path I</bar>, instead of a path I<//foo/bar> which you
might actually want.

=back

=head1 OPTIONS

Specify the L<Plack::Test> backend using the environment
variable C<PLACK_TEST_IMPL> or C<$Plack::Test::Impl> package variable.

The available values for the backend are:

=over 4

=item MockHTTP

(Default) Creates a PSGI env hash out of HTTP::Request object, runs
the PSGI application in-process and returns HTTP::Response.

=item Server

Runs one of Plack::Handler backends (C<Standalone> by default) and
sends live HTTP requests to test.

=item ExternalServer

Runs tests against an external server specified in the
C<PLACK_TEST_EXTERNALSERVER_URI> environment variable instead of spawning the
application in a server locally.

=back

For instance, test your application with the C<HTTP::Server::ServerSimple>
server backend with:

  > env PLACK_TEST_IMPL=Server PLACK_SERVER=HTTP::Server::ServerSimple \
    prove -l t/test.t

=head1 AUTHOR

Tatsuhiko Miyagawa

=cut
