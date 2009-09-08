package Plack::Impl;
use strict;

1;

__END__

=head1 NAME

Plack::Impl - Standard interface for Plack implementations

=head1 SYNOPSIS

  my $impl = Plack::Impl::XXX->new(%args);
  $impl->run($app);

=head1 DESCRIPTION

Plack::Impl is a base class of Plack PSGI implementations. Plack::Impl
may inherit from this class, but as long as they implement the methods
defined as an Impl unified interface, they do not need to inherit
Plack::Impl.

=head1 METHODS

=over 4

=item new

  $impl = Plack::Impl::XXX->new(%args);

Creates a new implementation object. I<%args> can take arbitrary
parameters per implementations but common parameters are:

=over 8

=item port

Port number the server listens to.

=item address

Address the server listens to. Set to undef to listen any interface.

=back

=item run

  $impl->run($app)

Starts the server process and when a request comes in, run the PSGI application passed in C<$app>.

=back

=head1 SEE ALSO

rackup

=cut

