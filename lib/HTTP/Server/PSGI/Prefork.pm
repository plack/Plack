package HTTP::Server::PSGI::Prefork;
use strict;
use warnings;

use parent qw(HTTP::Server::PSGI);
use Parallel::Prefork;

sub new {
    my($class, %args) = @_;
    my $self = $class->SUPER::new(
        max_keepalive_reqs => 100,
        %args,
    );
    $self->{max_workers} = $args{max_workers} || 10;
    $self->{max_reqs_per_child} = $args{max_reqs_per_child} || 100;
    $self;
}

sub run {
    my($self, $app) = @_;
    $self->setup_listener();
    my $pm = Parallel::Prefork->new({
        max_workers => $self->{max_workers},
        trap_signals => {
            TERM => 'TERM',
            HUP  => 'TERM',
        },
    });
    while ($pm->signal_received ne 'TERM') {
        $pm->start and next;
        $self->accept_loop($app, $self->{max_reqs_per_child});
        $pm->finish;
    }
    $pm->wait_all_children;
}

1;

__END__

=head1 NAME

HTTP::Server::PSGI::Prefork - Prefork standalone HTTP server

=head1 SYNOPSIS

  use HTTP::Server::PSGI;

  my $server = HTTP::Server::PSGI->new(
      host => "127.0.0.1",
      port => 9091,
      timeout => 120,
      max_keepalive_reqs => 20,
      keepalive_timeout => 5,
      max_workers => 10,
      max_reqs_per_child => 320,
  );

  $server->run($app);

=head1 DESCRIPTION

HTTP::Server::PSGI::Prefork is a prefork standalone HTTP
server. HTTP/1.0 and Keep-Alive requests are supported.

Some features in HTTP/1.1, notably chunked requests, responses and
pipeline requests are B<NOT> supported yet.

=head1 AUTHOR

Kazuho Oku

=head1 SEE ALSO

L<HTTP::Server::PSGI>

=cut
