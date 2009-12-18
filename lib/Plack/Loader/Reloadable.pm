package Plack::Loader::Reloadable;
use strict;
use warnings;
use Plack::Util;
use Try::Tiny;
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
    $self->{path} = $path;

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
                    $server->run($app->());
                } catch {
                    warn $_;
                };
                exit;
            }
        }
    }
}

sub valid_file {
    my($self, $file) = @_;
    $file->{path} !~ m![/\\][\._]|\.bak$|~$!;
}

sub monitor_loop {
    my ( $self, $parent_pid ) = @_;

    my $watcher;
    try {
        # delay load in forked child for stupid FSEvents limitation
        require Filesys::Notify::Simple;
        $watcher = Filesys::Notify::Simple->new($self->{path});
    } catch {
        Carp::carp("Automatic reloading is disabled: $_\n");
    };

    return unless $watcher;

    while (1) {
        $watcher->wait(sub {
            my @events = @_;
            @events = grep $self->valid_file($_), @events;
            return unless @events;

            for my $ev (@events) {
                warn "-- $ev->{path} updated.\n";
            }

            warn "Reloading the server...\n";
            kill 'HUP' => $parent_pid;

            # no more than one restart per second
            sleep 1;
        });
    }
}

sub load { shift->wrapper(load => @_) }
sub auto {
    unless ($ENV{PLACK_SERVER}) {
        warn "Automatic server selection is disabled with plackup -r or -R. Set it with -s or PLACK_SERVER\n";
    }
    shift->wrapper(auto => @_);
}

1;
