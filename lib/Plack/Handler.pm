package Plack::Handler;
use strict;

1;

__END__

=head1 NAME

Plack::Handler - Connects PSGI applications and Web servers

=head1 SYNOPSIS

  package Plack::Handler::AwesomeWebServer;
  sub new {
      my($class, %opt) = @_;
      ...
      return $self;
  }

  sub run {
      my($self, $app) = @_;
      # launch the AwesomeWebServer and run $app in the loop
  }

  # then from command line
  plackup -s AwesomeWebServer -a app.psgi

=head1 DESCRIPTION

Plack::Handler defines an adapter (connector) interface to adapt
L<plackup> and L<Plack::Runner> to various PSGI web servers, such as
Apache2 for mod_perl and Standalone for L<HTTP::Server::PSGI>.

It is an empty class, and as long as they implement the methods
defined as an Server adapter interface, they do not need to inherit
Plack::Handler.

If you write a new handler for existing web servers, I recommend you
to include the full name of the server module after I<Plack::Handler>
prefix, like L<Plack::Handler::Net::Server::Coro> if you write a
handler for L<Net::Server::Coro>. That way you'll be using plackup
command line option like:

  plackup -s Net::Server::Coro

that makes it easy to figure out which web server you're going to use.

=head1 METHODS

=over 4

=item new

  $server = FooBarServer->new(%args);

Creates a new adapter object. I<%args> can take arbitrary parameters
to configure server environments but common parameters are:

=over 8

=item port

Port number the server listens to.

=item host

Address the server listens to. Set to undef to listen any interface.

=back

=item run

  $server->run($app);

Starts the server process and when a request comes in, run the PSGI
application passed in C<$app> in the loop.

=item register_service

  $server->register_service($app);

Optional interface if your server should run in parallel with other
event loop, particularly L<AnyEvent>. This is the same as C<run> but
doesn't run the main loop.

=back

=head1 SEE ALSO

rackup

=cut

