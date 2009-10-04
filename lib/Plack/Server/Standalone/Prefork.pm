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
