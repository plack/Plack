package Plack::Handler::Net::FastCGI;
use strict;
use Plack::Util;
use IO::Socket             qw[];
use Net::FastCGI::Constant qw[:common :type :flag :role :protocol_status];
use Net::FastCGI::Protocol qw[:all];

sub DEBUG () { 0 }

sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;
    $self->{listen} ||= [ ":$self->{port}" ] if $self->{port};
    $self->{values} ||= {
        FCGI_MAX_CONNS   => 1,  # maximum number of concurrent transport connections this application will accept
        FCGI_MAX_REQS    => 1,  # maximum number of concurrent requests this application will accept
        FCGI_MPXS_CONNS  => 0,  # this implementation can't multiplex
    };
    $self;
}

sub run {
    my ($self, $app) = @_;
    $self->{app} = $app;

    my $socket;
    my $proto;
    my $port;

    if ($self->{listen}) {
        $port = $self->{listen}->[0];
        if ($port =~ s/^://) {
            $proto = 'tcp';
            $socket = IO::Socket::INET->new(
                Listen    => 5,
                LocalPort => $port,
                Reuse     => 1
            ) or die "Couldn't create listener socket: $!";
        } else {
            $proto = 'unix';
            $socket = IO::Socket::UNIX->new(
                Listen    => 5,
                Local     => $port,
            ) or die "Couldn't create UNIX listener socket: $!";
        }
    }
    else {
        (-S STDIN)
          || die "Standard input is not a socket: specify a listen location";
        $socket = \*STDIN;
        $socket->autoflush(1);
    }

    $self->{server_ready}->({
        host  => 'localhost',
        port  => $port,
        proto => $proto,
        server_software => 'Plack::Handler::Net::FastCGI',
    }) if $self->{server_ready} && $proto;

    while (my $c = $socket->accept) {
        $self->process_connection($c);
    }
}

sub process_request {
    my($self, $env, $stdin, $stdout, $stderr) = @_;

    $env = {
        %$env,
        'psgi.version'      => [1,1],
        'psgi.url_scheme'   => ($env->{HTTPS}||'off') =~ /^(?:on|1)$/i ? 'https' : 'http',
        'psgi.input'        => $stdin,
        'psgi.errors'       => $stderr,
        'psgi.multithread'  => Plack::Util::FALSE,
        'psgi.multiprocess' => Plack::Util::FALSE, # xxx?
        'psgi.run_once'     => Plack::Util::FALSE,
        'psgi.streaming'    => Plack::Util::TRUE,
        'psgi.nonblocking'  => Plack::Util::FALSE,
    };

    delete $env->{HTTP_CONTENT_TYPE};
    delete $env->{HTTP_CONTENT_LENGTH};

    my $res = Plack::Util::run_app $self->{app}, $env;

    if (ref $res eq 'ARRAY') {
        $self->_handle_response($res, $stdout);
    } elsif (ref $res eq 'CODE') {
        $res->(sub {
            $self->_handle_response($_[0], $stdout);
        });
    } else {
        die "Bad response $res";
    }
}

sub _handle_response {
    my ($self, $res, $stdout) = @_;

    my $hdrs;
    $hdrs = "Status: $res->[0]\015\012";

    my $headers = $res->[1];
    while (my ($k, $v) = splice @$headers, 0, 2) {
        $hdrs .= "$k: $v\015\012";
    }
    $hdrs .= "\015\012";

    print {$stdout} $hdrs;

    my $cb = sub { print {$stdout} $_[0] };
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

sub read_record {
    @_ == 1 || die(q/Usage: read_record(io)/);
    my ($io) = @_;
    no warnings 'uninitialized';
    read($io, my $header, FCGI_HEADER_LEN) == FCGI_HEADER_LEN
      || return;
    my ($type, $request_id, $clen, $plen) = parse_header($header);
       (!$clen || read($io, my $content, $clen) == $clen)
    && (!$plen || read($io, my $padding, $plen) == $plen)
      || return;
    $content = '' if !$clen;
    return ($type, $request_id, $content);
}

sub process_connection {
    my($self, $socket) = @_;

    my ( $current_id,  # id of the request we are currently processing
         $stdin,       # buffer for stdin
         $stdout,      # buffer for stdout
         $stderr,      # buffer for stderr
         $params,      # buffer for params (environ)
         $output,      # buffer for output
         $done,        # done with connection?
         $keep_conn ); # more requests on this connection?

    ($current_id, $stdin, $stdout, $stderr) = (0, '', '', '');

    while (!$done) {
        my ($type, $request_id, $content) = read_record($socket)
          or last;

        if (DEBUG) {
            warn '< ', dump_record($type, $request_id, $content), "\n";
        }

        if ($request_id == FCGI_NULL_REQUEST_ID) {
            if ($type == FCGI_GET_VALUES) {
                my $query = parse_params($content);
                my %reply = map { $_ => $self->{values}->{$_} }
                            grep { exists $self->{values}->{$_} }
                            keys %$query;
                $output = build_record(FCGI_GET_VALUES_RESULT,
                    FCGI_NULL_REQUEST_ID, build_params(\%reply));
            }
            else {
                $output = build_unknown_type_record($type);
            }
        }
        elsif ($request_id != $current_id && $type != FCGI_BEGIN_REQUEST) {
            # ignore inactive requests (FastCGI Specification 3.3)
        }
        elsif ($type == FCGI_ABORT_REQUEST) {
            $current_id = 0;
            ($stdin, $stdout, $stderr, $params) = ('', '', '', '');
        }
        elsif ($type == FCGI_BEGIN_REQUEST) {
            my ($role, $flags) = parse_begin_request_body($content);
            if ($current_id || $role != FCGI_RESPONDER) {
                $output = build_end_request_record($request_id, 0, 
                    $current_id ? FCGI_CANT_MPX_CONN : FCGI_UNKNOWN_ROLE);
            }
            else {
                $current_id = $request_id;
                $keep_conn  = ($flags & FCGI_KEEP_CONN);
            }
        }
        elsif ($type == FCGI_PARAMS) {
            $params .= $content;
        }
        elsif ($type == FCGI_STDIN) {
            $stdin .= $content;

            unless (length $content) {
                open(my $in, '<', \$stdin)
                  || die(qq/Couldn't open scalar as fh: '$!'/);

                open(my $out, '>', \$stdout)
                  || die(qq/Couldn't open scalar as fh: '$!'/);

                open(my $err, '>', \$stderr)
                  || die(qq/Couldn't open scalar as fh: '$!'/);

                $self->process_request(parse_params($params), $in, $out, $err);

                $done   = 1 unless $keep_conn;
                $output = build_end_request($request_id, 0,
                    FCGI_REQUEST_COMPLETE, $stdout, $stderr);

                # prepare for next request
                $current_id = 0;
                ($stdin, $stdout, $stderr, $params) = ('', '', '', '');
            }
        }
        else {
            warn(qq/Received an unknown record type '$type'/);
        }

        if ($output) {
            print {$socket} $output
              || die(qq/Couldn't write: '$!'/);

            if (DEBUG) {
                while (length $output) {
                    my ($type, $rid, $clen, $plen) = parse_header($output);
                    my $content = substr($output, FCGI_HEADER_LEN, $clen);
                    warn '> ', dump_record($type, $rid, $content), "\n";
                    substr($output, 0, FCGI_HEADER_LEN + $clen + $plen, '');
                }
            }

            $output = '';
        }
    }

    if (DEBUG && !$done && $!) {
        warn(qq/Request was prematurely aborted: '$!'/);
    }
}

1;

__END__

=head1 NAME

Plack::Handler::Net::FastCGI - FastCGI handler for Plack using Net::FastCGI

=head1 SYNOPSIS

  # Run as a standalone daemon using TCP port
  plackup -s Net::FastCGI --listen :9090

=head1 DESCRIPTION

This is a handler module to run any PSGI application as a standalone
FastCGI daemon using L<Net::FastCGI>

=head2 OPTIONS

=over 4

=item listen

    listen => ':8080'

Listen on a socket path, hostname:port, or :port.

=item port

listen via TCP on port on all interfaces (Same as C<< listen => ":$port" >>)

=back

=head1 AUTHORS

Christian Hansesn

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plack::Handler::FCGI>

=cut
