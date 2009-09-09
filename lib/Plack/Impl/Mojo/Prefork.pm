package Plack::Impl::Mojo::Prefork;
use strict;
use base qw(Plack::Impl::Mojo);
sub mojo_daemon_class { 'Mojo::Server::Daemon::Prefork' }
sub is_multiprocess { Plack::Util::TRUE }

1;

__END__

=head1 NAME

Plack::Impl::Mojo::Prefork - Use Mojo's prefork server

=head1 SYNOPSIS

  use Plack::Impl::Mojo::Prefork;

  my $server = Plack::Impl::Mojo::Prefork->new(
      host => $host,
      port => $port,
  );
  $server->run($app);

=cut
