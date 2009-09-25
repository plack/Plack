package Perlbal::Plugin::PSGI;
use strict;
use Perlbal;
use Plack::Util;
use Plack::HTTPParser qw(parse_http_request);
use HTTP::Status;

sub register {
    my ($class, $svc) = @_;
    $svc->register_hook('PSGI', 'start_http_request', sub { Perlbal::Plugin::PSGI::handle_request($svc, $_[0]); });
}

sub handle_request {
    my $svc = shift;
    my $pb = shift;

    my $app = $svc->{extra_config}->{_psgi_app};
    unless (defined $app) {
        return $pb->send_response(500, "No PSGI app is configured for this service");
    }

    my $hdr = $pb->{req_headers} or return 0;

    my $env = {
        'psgi.version'      => [ 1, 0 ],
        'psgi.errors'       => Plack::Util::inline_object(print => sub { Perlbal::log('error', @_) }),
        'psgi.url_scheme'   => 'http',
        'psgi.nonblocking'  => Plack::Util::TRUE,
        'psgi.run_once'     => Plack::Util::FALSE,
        'psgi.multithread'  => Plack::Util::FALSE,
        'psgi.multiprocess' => Plack::Util::FALSE,
        REMOTE_ADDR         => $pb->{peer_ip},
        SERVER_NAME         => (split /:/, $svc->{listen})[0],
        SERVER_PORT         => (split /:/, $svc->{listen})[1],
    };

    parse_http_request($pb->{headers_string}, $env);

    if ($env->{REQUEST_METHOD} eq 'POST') {
        my $buf_ref = $pb->read($env->{CONTENT_LENGTH}) || \"";
        open my $input, "<", $buf_ref;
        $env->{'psgi.input'} = $input;
    }

    my $res = Plack::Util::run_app $app, $env;

    $pb->write("HTTP/1.0 $res->[0] @{[ HTTP::Status::status_message($res->[0]) ]}\015\012");
    while (my($k, $v) = splice @{$res->[1]}, 0, 2) {
        $pb->write("$k: $v\015\012");
    }
    $pb->write("\015\012");

    if (Plack::Util::is_real_fh($res->[2])) {
        $pb->reproxy_fh($res->[2], -s $res->[2]);
    } else {
        Plack::Util::foreach($res->[2], sub { $pb->write(@_) });
        $pb->write(sub { $pb->http_response_sent });
    }
}

sub handle_psgi_app_command {
    my $mc = shift->parse(qr/^psgi_app\s*=\s*(\S+)$/, "usage: PSGI_APP=<path>");
    my ($app_path) = $mc->args;

    my $handler = do $app_path;
    unless (defined $handler && ref $handler eq 'CODE') {
        return $mc->err("Failed to load $app_path: " . ($! || $@))
    }

    my $svcname;
    unless ($svcname ||= $mc->{ctx}{last_created}) {
        return $mc->err("No service name in context from CREATE SERVICE <name> or USE <service_name>");
    }

    my $svc = Perlbal->service($svcname);
    return $mc->err("Non-existent service '$svcname'") unless $svc;

    my $cfg = $svc->{extra_config}->{_psgi_app} = $handler;

    return 1;
}

sub unregister {
    my ($class, $svc) = @_;
    $svc->unregister_hooks('PSGI');
    return 1;
}

sub load {
    Perlbal::register_global_hook('manage_command.psgi_app', \&Perlbal::Plugin::PSGI::handle_psgi_app_command);
    return 1;
}

sub unload {
    return 1;
}

1;

=head1 NAME

Perlbal::Plugin::PSGI - PSGI web server on Perlbal

=head1 SYNOPSIS

  LOAD PSGI
  CREATE SERVICE psgi
    SET role    = web_server
    SET listen  = 127.0.0.1:80
    SET plugins = psgi
    PSGI_APP    = /path/to/app.psgi
  ENABLE psgi

=head1 DESCRIPTION

This is a Perlbal plugin to asllow any PSGI application run natively
inside Perlbal process.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

Based on Perlbal::Plugin::Cgilike written by Martin Atkins.

=cut
