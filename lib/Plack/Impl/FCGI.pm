package Plack::Impl::FCGI;
use strict;
use warnings;
use constant RUNNING_IN_HELL => $^O eq 'MSWin32';

use Plack::Util;
use FCGI;

sub new {
    my $class = shift;
    my $self  = bless {@_}, $class;

    $self->{leave_umask} ||= 0;
    $self->{keep_stderr} ||= 0;
    $self->{nointr}      ||= 0;
    $self->{detach}      ||= 0;
    $self->{manager}     ||= 'FCGI::ProcManager';
    $self->{nproc}       ||= 1;
    $self->{pidfile}     ||= undef;

    $self;
}

sub run {
    my ($self, $app) = @_;

    my $sock = 0;
    if ($self->{listen}) {
        my $old_umask = umask;
        unless ($self->{leave_umask}) {
            umask(0);
        }
        $sock = FCGI::OpenSocket( $self->{listen}, 100 )
            or die "failed to open FastCGI socket: $!";
        unless ($self->{leave_umask}) {
            umask($old_umask);
        }
    }
    elsif (!RUNNING_IN_HELL) {
        -S STDIN
            or die "STDIN is not a socket: specify a listen location";
    }

    my %env;
    while (my ($k, $v) = each %ENV) {
        next unless $k =~ qr/^(?:REQUEST_METHOD|SCRIPT_NAME|PATH_INFO|QUERY_STRING|SERVER_NAME|SERVER_PORT|SERVER_PROTOCOL|CONTENT_LENGTH|CONTENT_TYPE|REMOTE_ADDR)$|^HTTP_/;
        $env{$k} = $v;
    }
    $env{'HTTP_COOKIE'} ||= $ENV{COOKIE};
    $env{'psgi.version'} = [1,0];
    $env{'psgi.url_scheme'} = ($ENV{HTTPS}||'off') =~ /^(?:on|1)$/i ? 'https' : 'http';
    $env{'psgi.input'}  = *STDIN;
    $env{'psgi.errors'} = $self->{keep_stderr} ? *STDOUT : *STDERR;
    $env{'psgi.multithread'}  = Plack::Util::FALSE;
    $env{'psgi.multiprocess'} = Plack::Util::TRUE;
    $env{'psgi.run_once'}     = Plack::Util::FALSE;

    my $request = FCGI::Request(
        \*STDIN, \*STDOUT,
        ($self->{keep_stderr} ? \*STDOUT : \*STDERR), \%env, $sock,
        ($self->{nointr} ? 0 : &FCGI::FAIL_ACCEPT_ON_INTR),
    );

    my $proc_manager;

    if ($self->{listen}) {
        $self->daemon_fork if $self->{detach};

        if ($self->{manager}) {
            Plack::Util::load_class($self->{manager});
            $proc_manager = $self->{manager}->new({
                n_processes => $self->{nproc},
                pid_fname   => $self->{pidfile},
            });

            # detach *before* the ProcManager inits
            $self->daemon_detach if $self->{detach};

            $proc_manager->pm_manage;
        }
        elsif ($self->{detach}) {
            $self->daemon_detach;
        }
    }

    while ($request->Accept >= 0) {
        $proc_manager && $proc_manager->pm_pre_dispatch;

        my $res = $app->(\%env);
        print "Status: $res->[0]\n";
        my $headers = $res->[1];
        while (my ($k, $v) = splice @$headers, 0, 2) {
            print "$k: $v\n";
        }
        print "\n";

        my $body = $res->[2];
        my $cb = sub { print STDOUT $_[0] };

        Plack::Util::foreach($body, $cb);

        $proc_manager && $proc_manager->pm_post_dispatch();
    }
}

sub daemon_fork {
    require POSIX;
    fork && exit;
}

sub daemon_detach {
    my $self = shift;
    print "FastCGI daemon started (pid $$)\n";
    open STDIN,  "+</dev/null" or die $!; ## no critic
    open STDOUT, ">&STDIN"     or die $!;
    open STDERR, ">&STDIN"     or die $!;
    POSIX::setsid();
}

1;
