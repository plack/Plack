package Plack::Loader::Reloadable;
use strict;
use warnings;
use Plack::Util;
use Try::Tiny;
use File::ChangeNotify;
use POSIX qw(WNOHANG);


sub wrapper {
    my $self = shift;
    my($meth, @args) = @_;

    my $server = Plack::Loader->$meth(@args);

    Plack::Util::inline_object
        run => sub { my $app = shift; $self->run_server($server, $app) };
}

sub new {
    my($class, $path) = @_;

    my $self = bless {}, shift;
    $self->{watcher} = File::ChangeNotify->instantiate_watcher(
        directories => [ $path ],
    );

    return $self;
}

sub run_server {
    my($self, $server, $app) = @_;

    my $parent_pid = $$;
    my $monitor_pid = fork;

    if (!defined $monitor_pid) {
        die "Can't fork: $!";
    } elsif ($monitor_pid == 0) {
        $self->monitor_loop($parent_pid);
        exit;
    } else {
        start_server: {
            my $server_pid = fork;

            if ( !defined $server_pid ) {
                die "Can't fork: $!";
            } elsif ( $server_pid > 0 ) {
                my $restart;
				
                local $SIG{HUP} = sub {
                    unless ( $restart++ ) {
                        kill TERM => $server_pid;
                    }
                };

                1 until waitpid($server_pid, 0) == $server_pid;

                if ( $restart ) {
                    redo start_server;
                } else {
                    kill TERM => $monitor_pid;
                    waitpid $monitor_pid, 0;
                    exit;
                }
            } else {
                try {
                    $server->run($app)
                } catch {
                    warn $_;
                };
                exit;
            }
        }
    }
}

sub monitor_loop {
    my ( $self, $parent_pid ) = @_;

    my $watcher = $self->{watcher};

    while ( my @events = $watcher->wait_for_events() ) {
        for my $ev (@events) {
            warn "-- $ev->{path} updated.\n";
        }

        kill 'HUP' => $parent_pid;

        # no more than one restart per second
        sleep 1;
        $watcher->new_events();
    }
}

sub load { shift->wrapper(load => @_) }
sub auto { shift->wrapper(auto => @_) }

1;
