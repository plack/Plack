package Plack::Server::Standalone;
use strict;
use warnings;

# for temporary backward compat
use parent qw( HTTP::Server::PSGI );

sub new {
    my($class, %args) = @_;
    bless { args => \%args }, $class;
}

sub _fork_and_start {
    my($self, $builder) = @_;

    my $pid = fork;
    die "Can't fork: $!" unless defined $pid;

    return $self->run($builder->()) if $pid == 0; # child

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

sub run_with_reload {
    my($self, $builder, %args) = @_;

    $self->_fork_and_start($builder);

    require Filesys::Notify::Simple;
    my $watcher = Filesys::Notify::Simple->new($args{watch});
    warn "Watching @{$args{watch}} for file updates.\n";

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
        $self->_fork_and_start($builder);
    }
}

sub run {
    my($self, $app) = @_;
    $self->_server->run($app);
}

sub _server {
    my $self = shift;
    HTTP::Server::PSGI->new(%{$self->{args}});
}

1;

__END__

=head1 NAME

Plack::Server::Standalone - adapters for HTTP::Server::PSGI

=head1 SYNOPSIS

  % plackup -s Standalone \
      --host 127.0.0.1 --port 9091 --timeout 120

=head1 DESCRIPTION

Plack::Server::Standalone is an adapter for default Plack server
implementation L<HTTP::Server::PSGI>.

=head1 CONFIGURATIONS

This adapter automatically loads Prefork implementation when
C<max-workers> is set, but otherwise the default HTTP::Server::PSGI
which is single process.

=over 4

=item host

Host the server binds to. Defaults to all interfaces.

=item port

Port number the server listens on. Defaults to 8080.

=item timeout

Number of seconds a request times out. Defaults to 300.

=item max-keepalive-reqs

Max requests per a keep-alive request. Defaults to 1, which means Keep-alive is off.

=item keepalive-timeout

Number of seconds a keep-alive request times out. Defaults to 2.

=item max-workers

Number of prefork workers. Defaults to 10.

=item max-reqs-per-child

Number of requests per worker to process. Defaults to 100.

=item max-keepalive-reqs

Max requests per a keep-alive request. Defaults to 100.

=back

=head1 AUTHOR

Kazuho Oku

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<HTTP::Server::PSGI>

=cut
