package Plack::Server;
use strict;

1;

__END__

=head1 NAME

Plack::Server - Standard interface for Plack implementations

=head1 SYNOPSIS

  package FooBarServer;
  sub new {
      my($class, %opt) = @_;
      ...
      return $self;
  }

  sub run {
      my($self, $app) = @_;
      # launch the server and run $app in the loop
  }

  # then from command line
  plackup -s +FooBarServer -a app.psgi

=head1 DESCRIPTION

Plack::Server is an abstract interface (but not actually a base class)
of Plack PSGI implementations. As long as they implement the methods
defined as an Server unified interface, they do not need to inherit
Plack::Server.

=head1 METHODS

=over 4

=item new

  $server = FooBarServer->new(%args);

Creates a new implementation object. I<%args> can take arbitrary
parameters per implementations but common parameters are:

=over 8

=item port

Port number the server listens to.

=item host

Address the server listens to. Set to undef to listen any interface.

=back

=item run

  $server->run($app);

Starts the server process and when a request comes in, run the PSGI application passed in C<$app> in the loop.

=item register_service

  $server->register_service($app);

Optional interface if your server should run in parallel with other
event loop, particularly L<AnyEvent>. This is the same as C<run> but
doesn't run the main loop.

=back

=head1 SEE ALSO

rackup

=cut

