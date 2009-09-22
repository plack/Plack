package Plack::Middleware::Restarter;
use strict;
use warnings;
use base qw/Plack::Middleware/;
use File::ChangeNotify;

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    $args{filter} ||= qr{\.(pm|yml|yaml|conf)$};
    bless {%args}, $class;
}

sub to_app {
    my $self = shift;
    my $pid = fork();
    if (!defined($pid)) {
        die "cannot fork: '$!'";
    } elsif ($pid > 0) {
        # parent(watcher process)
        close STDOUT;
        close STDIN;

        local $SIG{CHLD} = sub { exit }; # exit when child was dead.
        my $watcher = File::ChangeNotify->instantiate_watcher(
            %$self
        );
        while ( my @events = $watcher->wait_for_events() ) {
            kill 'HUP' => $pid;
            waitpid($pid, 0);
            exit;
        }
    } else {
        # child(main process)
        return $self->app(); # nop. This is same as 'sub { $self->app->(@_) }'
    }
}

1;
__END__

=head1 PORTABILITY

This module is not works on Win32/VMS etc(maybe).

