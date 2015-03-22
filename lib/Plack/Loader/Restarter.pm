package Plack::Loader::Restarter;
use strict;
use warnings;
use parent qw(Plack::Loader);
use Plack::Util;
use Try::Tiny;

sub new {
    my($class, $runner) = @_;
    bless { watch => [] }, $class;
}

sub preload_app {
    my($self, $builder) = @_;
    $self->{builder} = $builder;
}

sub set_restarter_callback {
    my( $self, $callback) = @_;
    $self->{callback} = $callback;
}

sub watch {
    my($self, @dir) = @_;
    push @{$self->{watch}}, @dir;
}

sub _fork_and_start {
    my($self, $server) = @_;

    delete $self->{pid}; # re-init in case it's a restart

    my $pid = fork;
    die "Can't fork: $!" unless defined $pid;

    if ($pid == 0) { # child
        return $server->run($self->{builder}->());
    } else {
        $self->{pid} = $pid;
    }
}

sub _kill_child {
    my $self = shift;

    my $pid = $self->{pid} or return;
    warn "Killing the existing server (pid:$pid)\n";
    kill 'TERM' => $pid;
    waitpid($pid, 0);
}

sub valid_file {
    my($self, $file) = @_;

    # vim temporary file is  4913 to 5036
    # http://www.mail-archive.com/vim_dev@googlegroups.com/msg07518.html
    if ( $file->{path} =~ m{(\d+)$} && $1 >= 4913 && $1 <= 5036) {
        return 0;
    }
    $file->{path} !~ m!\.(?:git|svn)[/\\]|\.(?:bak|swp|swpx|swx)$|~$|_flymake\.p[lm]$|\.#!;
}

sub run {
    my($self, $server) = @_;

    $self->_fork_and_start($server);
    return unless $self->{pid};

    require Filesys::Notify::Simple;
    my $watcher = Filesys::Notify::Simple->new($self->{watch});
    warn "Watching @{$self->{watch}} for file updates.\n";
    local $SIG{TERM} = sub { $self->_kill_child; exit(0); };

    while (1) {
        my @restart;

        # this is blocking
        $watcher->wait(sub {
            my @events = @_;
            @events = grep $self->valid_file($_), @events;
            return unless @events;

            @restart = @events;
        });

        next unless @restart;

        for my $ev (@restart) {
            warn "-- $ev->{path} updated.\n";
        }

        $self->_kill_child;
        warn "Successfully killed! Restarting the new server process.\n";

        if ( defined $self->{callback} ) {
          warn "Running restarter callback.\n";
          $self->{callback}->()
        }

        $self->_fork_and_start($server);
        return unless $self->{pid};
    }
}

1;

__END__

=head1 NAME

Plack::Loader::Restarter - Restarting loader

=head1 SYNOPSIS

  plackup -r -R paths

=head1 DESCRIPTION

Plack::Loader::Restarter is a loader backend that implements C<-r> and
C<-R> option for the L<plackup> script. It forks the server as a child
process and the parent watches the directories for file updates, and
whenever it receives the notification, kills the child server and
restart.

=head1 RUNNING CODE AS PART OF SERVER RESTART

Some times it is desirable to be able to run an arbitrary code callback when
the server restarts (e.g, the files you are watching for changes may need to
be processed in some way before being served, like Markdown to HTML
conversion.) C<Plack::Loader::Restarter> supports this via the
C<set_restarter_callback> method, like so:

    my $app = Plack::Runner->new();
    # this sets $app to use Loader::Restarter watching given directories
    $app->parse_options( '-R' => qw/ lib content / );
    my $loader = $app->loader;
    $loader->set_restarter_callback( sub { ... } );
    $app->run();

During the restart cycle, after the previous server process has been killed
and before the new one is started, the provided subroutine reference will be
called once, with an empty argument list.

=head1 SEE ALSO

L<Plack::Runner>, L<Catalyst::Restarter>

=cut
