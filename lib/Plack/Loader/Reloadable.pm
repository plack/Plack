package Plack::Loader::Reloadable;
use strict;
use warnings;
use Plack::Util;
use File::ChangeNotify;

my $starter;

sub wrapper {
    my $self = shift;
    my($meth, @args) = @_;
    $starter = sub {
        my $server = Plack::Loader->$meth(@args);
        Plack::Util::inline_object
            run => sub { my $app = shift; $self->run_server($server, $app) };
    };
    $starter->();
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

    my $pid = fork;
    if (!defined $pid) {
        die "Can't fork: $!";
    } elsif ($pid > 0) {
        # parent = watcher
        close STDOUT;
        close STDIN;

        while ( my @events = $self->{watcher}->wait_for_events() ) {
            for my $ev (@events) {
                warn "-- $ev->{path} updated.\n";
            }
            warn "Restarting the server.\n";
            kill 'INT' => $pid;
            waitpid($pid, 0);
            $self->restart_server($app);
            exit;
        }
    } else {
        # child = server
        $server->run($app);
    }
}

sub restart_server {
    my($self, $app) = @_;
    $starter->()->run($app);
}

sub load { shift->wrapper(load => @_) }
sub auto { shift->wrapper(auto => @_) }

1;
