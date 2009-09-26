package Plack::Server::Mojo::Prefork;
use strict;
use base qw(Plack::Server::Mojo);
sub mojo_daemon_class { 'Mojo::Server::Daemon::Prefork' }
sub is_multiprocess { Plack::Util::TRUE }

1;

__END__

=head1 NAME

Plack::Server::Mojo::Prefork - Use Mojo's prefork server

=head1 SYNOPSIS

  use Plack::Server::Mojo::Prefork;

  my $server = Plack::Server::Mojo::Prefork->new(
      host => $host,
      port => $port,
  );
  $server->run($app);

=cut
