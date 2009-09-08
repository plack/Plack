package Plack::Impl;

1;

__END__

=head1 NAME

Plack::Impl - Standard interface for Plack implementations

=head1 SYNOPSIS

  my $impl = Plack::Impl::XXX->new(%args);
  $impl->run($app);

=head1 DESCRIPTION

Plack::Impl subclasses are supposed to implement a pretty simple unified interface to run the PSGI application.

=head1 METHODS

=over 4

=item new

  $impl = Plack::Impl::XXX->new(%args);

Creates a new implementation object. I<%args> can take arbitrary
parameters per implementations but common parameters are:

=over 8

=item port

Port number the server listens to.

=item port

Address the server listens to. Set to undef to listen any interface.

=back

=over 4

=item run

  $impl->run($app)

Starts the server process and when a request comes in, run the PSGI application passed in C<$app>.

=back

=cut

