package Plack::Handler::FCGI;
use strict;
use warnings;
use constant RUNNING_IN_HELL => $^O eq 'MSWin32';

use Scalar::Util qw(blessed);
use Plack::Util;
use FCGI;
use HTTP::Status qw(status_message);
use URI;
use URI::Escape;

sub new {
    my $class = shift;
    my $self  = bless {@_}, $class;

    $self->{leave_umask} ||= 0;
    $self->{keep_stderr} ||= 0;
    $self->{nointr}      ||= 0;
    $self->{daemonize}   ||= $self->{detach}; # compatibility
    $self->{nproc}       ||= 1 unless blessed $self->{manager};
    $self->{pid}         ||= $self->{pidfile}; # compatibility
    $self->{listen}      ||= [ ":$self->{port}" ] if $self->{port}; # compatibility
    $self->{manager}     = 'FCGI::ProcManager' unless exists $self->{manager};

    $self;
}

sub run {
    my ($self, $app) = @_;

    my $sock = 0;
    if (-S STDIN) {
        # running from web server. Do nothing
        # Note it should come before listen check because of plackup's default
    } elsif ($self->{listen}) {
        my $old_umask = umask;
        unless ($self->{leave_umask}) {
            umask(0);
        }
        $sock = FCGI::OpenSocket( $self->{listen}->[0], 100 )
            or die "failed to open FastCGI socket: $!";
        unless ($self->{leave_umask}) {
            umask($old_umask);
        }
    } elsif (!RUNNING_IN_HELL) {
        die "STDIN is not a socket: specify a listen location";
    }

    my %env;
    my $request = FCGI::Request(
        \*STDIN, \*STDOUT,
        ($self->{keep_stderr} ? \*STDOUT : \*STDERR), \%env, $sock,
        ($self->{nointr} ? 0 : &FCGI::FAIL_ACCEPT_ON_INTR),
    );

    my $proc_manager;

    if ($self->{listen}) {
        $self->daemon_fork if $self->{daemonize};

        if ($self->{manager}) {
            if (blessed $self->{manager}) {
                for (qw(nproc pid)) {
                    die "Don't use '$_' when passing in a 'manager' object"
                        if $self->{$_};
                }
                $proc_manager = $self->{manager};
            } else {
                Plack::Util::load_class($self->{manager});
                $proc_manager = $self->{manager}->new({
                    n_processes => $self->{nproc},
                    pid_fname   => $self->{pid},
                    (exists $self->{proc_title}
                         ? (pm_title => $self->{proc_title}) : ()),
                });
            }

            # detach *before* the ProcManager inits
            $self->daemon_detach if $self->{daemonize};

            $proc_manager->pm_manage;
        }
        elsif ($self->{daemonize}) {
            $self->daemon_detach;
        }
    }

    while ($request->Accept >= 0) {
        $proc_manager && $proc_manager->pm_pre_dispatch;

        my $env = {
            %env,
            'psgi.version'      => [1,1],
            'psgi.url_scheme'   => ($env{HTTPS}||'off') =~ /^(?:on|1)$/i ? 'https' : 'http',
            'psgi.input'        => *STDIN,
            'psgi.errors'       => *STDERR, # FCGI.pm redirects STDERR in Accept() loop, so just print STDERR
                                            # print to the correct error handle based on keep_stderr
            'psgi.multithread'  => Plack::Util::FALSE,
            'psgi.multiprocess' => Plack::Util::TRUE,
            'psgi.run_once'     => Plack::Util::FALSE,
            'psgi.streaming'    => Plack::Util::TRUE,
            'psgi.nonblocking'  => Plack::Util::FALSE,
            'psgix.harakiri'    => defined $proc_manager,
        };

        delete $env->{HTTP_CONTENT_TYPE};
        delete $env->{HTTP_CONTENT_LENGTH};

        # lighttpd munges multiple slashes in PATH_INFO into one. Try recovering it
        my $uri = URI->new("http://localhost" .  $env->{REQUEST_URI});
        $env->{PATH_INFO} = uri_unescape($uri->path);
        $env->{PATH_INFO} =~ s/^\Q$env->{SCRIPT_NAME}\E//;

        if ($env->{SERVER_SOFTWARE} && $env->{SERVER_SOFTWARE} =~ m!lighttpd[-/]1\.(\d+\.\d+)!) {
            no warnings;
            if ($ENV{PLACK_ENV} eq 'development' && $1 < 4.23 && $env->{PATH_INFO} eq '') {
                warn "You're using lighttpd 1.$1 and appear to mount your FastCGI handler under the root ('/'). ",
                     "It's known to be causing issues because of the lighttpd bug. You're recommended to enable ",
                     "LighttpdScriptNameFix middleware, or upgrade lighttpd to 1.4.23 or later and include ",
                     "'fix-root-scriptname' flag in 'fastcgi.server'. See perldoc Plack::Handler::FCGI for details. ",
                     "This friendly warning will go away in the next major release of Plack.";
            }
            $env->{SERVER_NAME} =~ s/:\d+$//; # cut off port number
        }

        # root access for mod_fastcgi
        if (!exists $env->{PATH_INFO}) {
            $env->{PATH_INFO} = '';
        }

        my $res = Plack::Util::run_app $app, $env;

        if (ref $res eq 'ARRAY') {
            $self->_handle_response($res);
        }
        elsif (ref $res eq 'CODE') {
            $res->(sub {
                $self->_handle_response($_[0]);
            });
        }
        else {
            die "Bad response $res";
        }

        # give pm_post_dispatch the chance to do things after the client thinks
        # the request is done
        $request->Finish;

        $proc_manager && $proc_manager->pm_post_dispatch();

        if ($proc_manager && $env->{'psgix.harakiri.commit'}) {
            $proc_manager->pm_exit("safe exit with harakiri");
        }
    }
}

sub _handle_response {
    my ($self, $res) = @_;

    *STDOUT->autoflush(1);
    binmode STDOUT;

    my $hdrs;
    my $message = status_message($res->[0]);
    $hdrs = "Status: $res->[0] $message\015\012";

    my $headers = $res->[1];
    while (my ($k, $v) = splice @$headers, 0, 2) {
        $hdrs .= "$k: $v\015\012";
    }
    $hdrs .= "\015\012";

    print STDOUT $hdrs;

    my $cb = sub { print STDOUT $_[0] };
    my $body = $res->[2];
    if (defined $body) {
        Plack::Util::foreach($body, $cb);
    }
    else {
        return Plack::Util::inline_object
            write => $cb,
            close => sub { };
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

__END__

=head1 NAME

Plack::Handler::FCGI - FastCGI handler for Plack

=head1 SYNOPSIS

  # Run as a standalone daemon
  plackup -s FCGI --listen /tmp/fcgi.sock --daemonize --nproc 10

  # Run from your web server like mod_fastcgi
  #!/usr/bin/env plackup -s FCGI
  my $app = sub { ... };

  # Roll your own
  my $server = Plack::Handler::FCGI->new(
      nproc  => $num_proc,
      listen => [ $port_or_socket ],
      detach => 1,
  );
  $server->run($app);


=head1 DESCRIPTION

This is a handler module to run any PSGI application as a standalone
FastCGI daemon or a .fcgi script.

=head2 OPTIONS

=over 4

=item listen

    listen => [ '/path/to/socket' ]
    listen => [ ':8080' ]

Listen on a socket path, hostname:port, or :port.

=item port

listen via TCP on port on all interfaces (Same as C<< listen => ":$port" >>)

=item leave-umask

Set to 1 to disable setting umask to 0 for socket open

=item nointr

Do not allow the listener to be interrupted by Ctrl+C

=item nproc

Specify a number of processes for FCGI::ProcManager

=item pid

Specify a filename for the pid file

=item manager

Specify a FCGI::ProcManager sub-class

=item daemonize

Daemonize the process.

=item keep-stderr

Send STDERR to STDOUT instead of the webserver

=back

=head2 WEB SERVER CONFIGURATIONS

=head3 nginx

This is an example nginx configuration to run your FCGI daemon on a
Unix domain socket and run it at the server's root URL (/).

  http {
    server {
      listen 3001;
      location / {
        set $script "";
        set $path_info $uri;
        fastcgi_pass unix:/tmp/fastcgi.sock;
        fastcgi_param  SCRIPT_NAME      $script;
        fastcgi_param  PATH_INFO        $path_info;
        fastcgi_param  QUERY_STRING     $query_string;
        fastcgi_param  REQUEST_METHOD   $request_method;
        fastcgi_param  CONTENT_TYPE     $content_type;
        fastcgi_param  CONTENT_LENGTH   $content_length;
        fastcgi_param  REQUEST_URI      $request_uri;
        fastcgi_param  SERVER_PROTOCOL  $server_protocol;
        fastcgi_param  REMOTE_ADDR      $remote_addr;
        fastcgi_param  REMOTE_PORT      $remote_port;
        fastcgi_param  SERVER_ADDR      $server_addr;
        fastcgi_param  SERVER_PORT      $server_port;
        fastcgi_param  SERVER_NAME      $server_name;
      }
    }
  }

If you want to host your application in a non-root path, then you
should mangle this configuration to set the path to C<SCRIPT_NAME> and
the rest of the path in C<PATH_INFO>.

See L<http://wiki.nginx.org/NginxFcgiExample> for more details.

=head3 Apache mod_fastcgi

You can use C<FastCgiExternalServer> as normal.

  FastCgiExternalServer /tmp/myapp.fcgi -socket /tmp/fcgi.sock

See L<http://www.fastcgi.com/mod_fastcgi/docs/mod_fastcgi.html#FastCgiExternalServer> for more details.

=head3 lighttpd

To host the app in the root path, you're recommended to use lighttpd
1.4.23 or newer with C<fix-root-scriptname> flag like below.

  fastcgi.server = ( "/" =>
     ((
       "socket" => "/tmp/fcgi.sock",
       "check-local" => "disable"
       "fix-root-scriptname" => "enable",
     ))

If you use lighttpd older than 1.4.22 where you don't have
C<fix-root-scriptname>, mouting apps under the root causes wrong
C<SCRIPT_NAME> and C<PATH_INFO> set. Also, mouting under the empty
root (C<"">) or a path that has a trailing slash would still cause
weird values set even with C<fix-root-scriptname>. In such cases you
can use L<Plack::Middleware::LighttpdScriptNameFix> to fix it.

To mount in the non-root path over TCP:

  fastcgi.server = ( "/foo" =>
     ((
       "host" = "127.0.0.1"
       "port" = "5000"
       "check-local" => "disable"
     ))

It's recommended that your mount path does B<NOT> have the trailing
slash. If you I<really> need to have one, you should consider using
L<Plack::Middleware::LighttpdScriptNameFix> to fix the wrong
B<PATH_INFO> values set by lighttpd.

=cut

=head1 SEE ALSO

L<Plack>

=cut

