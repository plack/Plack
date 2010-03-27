package Plack::Handler::FCGI::PP;
use strict;
use Plack::Util;
use IO::Socket::INET;
use Net::FastCGI::Constant qw[:all];
use Net::FastCGI::Protocol qw[:all];

sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;
    $self->{listen} ||= [ ":$self->{port}" ] if $self->{port};
    $self;
}

sub run {
    my ($self, $app) = @_;
    $self->{app} = $app;

    unless ($self->{listen}) {
        die "This handler doesn't run with STDIN. Run this as an external FCGI daemon";
    }

    my $socket;
    my $proto;

    if ($self->{listen}->[0] =~ s/^://) {
        $proto = 'tcp';
        $socket = IO::Socket::INET->new(
            Listen    => 5,
            LocalPort => $self->{listen}->[0],
            Reuse     => 1
        ) or die "Couldn't create listener socket: $!";
    } else {
        $proto = 'unix';
        $socket = IO::Socket::UNIX->new(
            Listen    => 5,
            Local     => $self->{listen}->[0],
        ) or die "Couldn't create UNIX listener socket: $!";
    }

    $self->{server_ready}->({
        host  => 'localhost',
        port  => $self->{listen}->[0],
        proto => $proto,
        server_software => 'Plack::Handler::FCGI::PP',
    }) if $self->{server_ready};

    while (my $c = $socket->accept) {
        $self->process_connection($c);
    }
}

sub process_request {
    my($self, $env, $stdin, $stdout) = @_;

    $env = {
        %$env,
        'psgi.version'      => [1,1],
        'psgi.url_scheme'   => ($env->{HTTPS}||'off') =~ /^(?:on|1)$/i ? 'https' : 'http',
        'psgi.input'        => $stdin,
        'psgi.errors'       => *STDERR, # xxx
        'psgi.multithread'  => Plack::Util::FALSE,
        'psgi.multiprocess' => Plack::Util::FALSE, # xxx?
        'psgi.run_once'     => Plack::Util::FALSE,
        'psgi.streaming'    => Plack::Util::TRUE,
        'psgi.nonblocking'  => Plack::Util::FALSE,
    };

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


# if the web-server asks for capabilities we respond with:
our $VALUES = {
    &FCGI_MAX_CONNS   => 1,     # we are single-threaded
    &FCGI_MAX_REQS    => 1000,  # how many requests we are accepting per connection
    &FCGI_MPXS_CONNS  => 0,     # this implementation can't multiplex
};

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
         $params,      # buffer for params (environ)
         $keep_conn ); # more requests on this connection?

    ($stdin, $stdout) = ('', '');

    #print "->";

  RECORD:
    while (my ($type, $request_id, $content) = read_record($socket)) {

        if ($request_id == FCGI_NULL_REQUEST_ID) {

            my $record;
            if ($type == FCGI_GET_VALUES) {
                my $values = parse_params($content);
                my %params = map { $_ => $VALUES->{$_} }
                            grep { exists $VALUES->{$_} }
                            keys %{$values};
                $record = build_record(FCGI_GET_VALUES_RESULT,
                    FCGI_NULL_REQUEST_ID, build_params(\%params));
            }
            else {
                $record = build_unknown_type_record($type);
            }

            print {$socket} $record
              || die(q/Couldn't write management record: '$!'/);

            next RECORD;
        }

        # ignore inactive requests (FastCGI Specification 3.3)
        if ( $current_id 
             && ($request_id != $current_id)
             && $type != FCGI_BEGIN_REQUEST) {
            next RECORD;
        }

        if ($type == FCGI_BEGIN_REQUEST) {
            my ($role, $flags) = parse_begin_request_body($content);

            if ($current_id || $role != FCGI_RESPONDER) {
                my $status = $current_id ? FCGI_CANT_MPX_CONN : FCGI_UNKNOWN_ROLE;
                my $record = build_end_request_record($request_id, 0, $status);

                print {$socket} $record
                  || die(q/Couldn't write end request record: '$!'/);
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
                # process request

                open(my $in, '<', \$stdin)
                  || die(qq/Couldn't open scalar as fh: $!/);

                open(my $out, '>', \$stdout)
                  || die(qq/Couldn't open scalar as fh: $!/);

                $self->process_request(parse_params($params), $in, $out);

                my $end = build_end_request($request_id, 0,
                    FCGI_REQUEST_COMPLETE, $stdout);

                print {$socket} $end
                  || die(q/Couldn't write end request response: '$!'/);

                last unless $keep_conn;

                #print ".";

                # prepare for next request
                $current_id = 0;
                $stdin      = '';
                $stdout     = '';
                $params     = '';
            }
        }
        else {
            warn qq/Received an unknown record type '$type'/;
        }
    }

    #print "\n";
    close($socket);
}



1;

__END__

=head1 NAME

Plack::Handler::FCGI::PP - FastCGI handler for Plack using Net::FastCGI

=head1 SYNOPSIS

  # Run as a standalone daemon using TCP port
  plackup -s FCGI::PP --listen :9090

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
