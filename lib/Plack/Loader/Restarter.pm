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

sub watch {
    my($self, @dir) = @_;
    push @{$self->{watch}}, @dir;
}

sub _fork_and_start {
    my($self, $server, $builder) = @_;

    my $pid = fork;
    die "Can't fork: $!" unless defined $pid;

    return $server->run($builder->()) if $pid == 0; # child

    $self->{pid} = $pid;
}

sub _kill_child {
    my $self = shift;

    my $pid = $self->{pid} or return;
    warn "Killing the existing server (pid:$pid)\n";
    kill INT => $pid;
    waitpid($pid, 0);
    warn "Successfully killed! Restarting the new server process.\n";
}

sub valid_file {
    my($self, $file) = @_;
    $file->{path} !~ m![/\\][\._]|\.bak$|~$!;
}

sub run {
    my($self, $server, $builder) = @_;

    $self->_fork_and_start($server, $builder);

    require Filesys::Notify::Simple;
    my $watcher = Filesys::Notify::Simple->new($self->{watch});
    warn "Watching @{$self->{watch}} for file updates.\n";

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
        $self->_fork_and_start($server, $builder);
    }
}

1;
