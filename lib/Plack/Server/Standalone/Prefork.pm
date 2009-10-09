package Plack::Server::Standalone::Prefork;
use strict;
use warnings;

use base qw(Plack::Server::Standalone);
use Parallel::Prefork;

sub new {
    my($class, %args) = @_;
    my $self = $class->SUPER::new(%args);
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

Plack::Server::Standalone::Prefork - Prefork standalone HTTP server

=head1 SYNOPSIS

  % plackup -s Standalone::Prefork \
      --host 127.0.0.1 --port 9091 --timeout 120 \
      --max_keepalive_reqs 20 --keepalive_timeout 5 \
      --max_workers 10 --max_reqs_per_child 320

=head1 DESCRIPTION

Plack::Server::Standalone::Prefork is a prefork standalone HTTP
server. HTTP/1.0 and Keep-Alive requests are supported.

Some features in HTTP/1.1, notably chunked requests, responses and
pipeline requests are B<NOT> supported yet.

=head1 CONFIGURATIONS

=over 4

=item host, port, timeout, max_keepalive_reqs, keepalive_timeout

Same as L<Plack::Server::Standalone>.

=item max_workers

Number of prefork workers. Defaults to 10.

=item max_reqs_per_child

Number of requests per worker to process. Defaults to 100.

=back

=head1 AUTHOR

Kazuho Oku

=head1 SEE ALSO

L<Plack::Server::Standalone>

=cut
