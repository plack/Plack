package Plack::Handler;
use strict;

1;

__END__

=head1 NAME

Plack::Handler - Adapters for PSGI servers

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

  # optional: reloading support
  sub run_with_reload {
      my($self, $builder, %args);
      # $builder is a coderef to get $app
      # $args{watch} is an array ref of directories
  }

  # then from command line
  plackup -s AwesomeWebServer -a app.psgi

=head1 DESCRIPTION

Plack::Handler defines an adapter interface to adapt L<plackup> and
L<Plack::Runner> to various PSGI web servers, such as Apache2 for
mod_perl and Standalone for L<HTTP::Server::PSGI>.

It is an empty class, and as long as they implement the methods
defined as an Server adapter interface, they do not need to inherit
Plack::Handler.

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

