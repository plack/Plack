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
    $self->{backlog}     ||= 100;
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
        $sock = FCGI::OpenSocket( $self->{listen}->[0], $self->{backlog} )
            or die "failed to open FastCGI socket: $!";
        unless ($self->{leave_umask}) {
            umask($old_umask);
        }
    } elsif (!RUNNING_IN_HELL) {
        die "STDIN is not a socket: specify a listen location";
    }

    @{$self}{qw(stdin stdout stderr)} 
      = (IO::Handle->new, IO::Handle->new, IO::Handle->new);

    my %env;
    my $request = FCGI::Request(
        $self->{stdin}, $self->{stdout}, $self->{stderr},
        \%env, $sock,
        ($self->{nointr} ? 0 : &FCGI::FAIL_ACCEPT_ON_INTR),
    );

    my $proc_manager;

    if ($self->{listen}) {
        $self->daemon_fork if $self->{daemonize};

        if ($self->{manager}) {
            if (blessed $self->{manager}) {
                for (qw(nproc pid proc_title)) {
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
            'psgi.input'        => $self->{stdin},
            'psgi.errors'       => 
                ($self->{keep_stderr} ? \*STDERR : $self->{stderr}),
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

        # root access for mod_fastcgi
        if (!exists $env->{PATH_INFO}) {
            $env->{PATH_INFO} = '';
        }

        # typical fastcgi_param from nginx might get empty values
        for my $key (qw(CONTENT_TYPE CONTENT_LENGTH)) {
            no warnings;
            delete $env->{$key} if exists $env->{$key} && $env->{$key} eq '';
        }

        if (defined(my $HTTP_AUTHORIZATION = $env->{Authorization})) {
            $env->{HTTP_AUTHORIZATION} = $HTTP_AUTHORIZATION;
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

    $self->{stdout}->autoflush(1);
    binmode $self->{stdout};

    my $hdrs;
    my $message = status_message($res->[0]);
    $hdrs = "Status: $res->[0] $message\015\012";

    my $headers = $res->[1];
    while (my ($k, $v) = splice @$headers, 0, 2) {
        $hdrs .= "$k: $v\015\012";
    }
    $hdrs .= "\015\012";

    print { $self->{stdout} } $hdrs;

    my $cb = sub { print { $self->{stdout} } $_[0] };
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

Specify either a FCGI::ProcManager subclass, or an actual FCGI::ProcManager-compatible object.

  use FCGI::ProcManager::Dynamic;
  Plack::Handler::FCGI->new(
      manager => FCGI::ProcManager::Dynamic->new(...),
  );

=item daemonize

Daemonize the process.

=item proc-title

Specify process title

=item keep-stderr

Send psgi.errors to STDERR instead of to the FCGI error stream.

=item backlog

Maximum length of the queue of pending connections

=back

=head2 WEB SERVER CONFIGURATIONS

In all cases, you will want to install L<FCGI> and L<FCGI::ProcManager>.
You may find it most convenient to simply install L<Task::Plack> which
includes both of these.

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

After installing C<mod_fastcgi>, you should add the C<FastCgiExternalServer>
directive to your Apache config:

  FastCgiExternalServer /tmp/myapp.fcgi -socket /tmp/fcgi.sock

  ## Then set up the location that you want to be handled by fastcgi:

  # EITHER from a given path
  Alias /myapp/ /tmp/myapp.fcgi/

  # OR at the root
  Alias / /tmp/myapp.fcgi/

Now you can use plackup to listen to the socket that you've just configured in Apache.

  $  plackup -s FCGI --listen /tmp/myapp.sock psgi/myapp.psgi

The above describes the "standalone" method, which is usually appropriate.
There are other methods, described in more detail at 
L<Catalyst::Engine::FastCGI/Standalone_server_mode> (with regards to Catalyst, but which may be set up similarly for Plack).

See also L<http://www.fastcgi.com/mod_fastcgi/docs/mod_fastcgi.html#FastCgiExternalServer>
for more details.

=head3 lighttpd

To host the app in the root path, you're recommended to use lighttpd
1.4.23 or newer with C<fix-root-scriptname> flag like below.

  fastcgi.server = ( "/" =>
     ((
       "socket" => "/tmp/fcgi.sock",
       "check-local" => "disable",
       "fix-root-scriptname" => "enable",
     ))

If you use lighttpd older than 1.4.22 where you don't have
C<fix-root-scriptname>, mounting apps under the root causes wrong
C<SCRIPT_NAME> and C<PATH_INFO> set. Also, mounting under the empty
root (C<"">) or a path that has a trailing slash would still cause
weird values set even with C<fix-root-scriptname>. In such cases you
can use L<Plack::Middleware::LighttpdScriptNameFix> to fix it.

To mount in the non-root path over TCP:

  fastcgi.server = ( "/foo" =>
     ((
       "host" = "127.0.0.1",
       "port" = "5000",
       "check-local" => "disable",
     ))

It's recommended that your mount path does B<NOT> have the trailing
slash. If you I<really> need to have one, you should consider using
L<Plack::Middleware::LighttpdScriptNameFix> to fix the wrong
B<PATH_INFO> values set by lighttpd.

=cut

=head2 Authorization

Most fastcgi configuration does not pass C<Authorization> headers to
C<HTTP_AUTHORIZATION> environment variable by default for security
reasons. Authentication middleware such as L<Plack::Middleware::Auth::Basic> or
L<Catalyst::Authentication::Credential::HTTP> requires the variable to
be set up. Plack::Handler::FCGI supports extracting the C<Authorization> environment
variable when it is configured that way.

Apache2 with mod_fastcgi:

  --pass-header Authorization

mod_fcgid:

  FcgiPassHeader Authorization

=head1 SEE ALSO

L<Plack>

=cut

