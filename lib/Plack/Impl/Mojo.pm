package Plack::Impl::Mojo;
use strict;
use warnings;
use base qw(Mojo::Base);
use Mojo::Server::Daemon;
use Plack::Util;

__PACKAGE__->attr([ 'host', 'port' ]);

my $mojo_daemon;

sub run {
    my($self, $app) = @_;

    my $mojo_app = Plack::Impl::Mojo::App->new(psgi_app => $app);

    $mojo_daemon = Mojo::Server::Daemon->new;
    $mojo_daemon->port($self->port)    if $self->port;
    $mojo_daemon->address($self->host) if defined $self->host;
    $mojo_daemon->app($mojo_app);
    $mojo_daemon->run;
}

package Plack::Impl::Mojo::App;
use base qw(Mojo);

__PACKAGE__->attr([ 'psgi_app' ]);

sub handler {
    my($self, $tx) = @_;

    my %env;
    $env{REQUEST_METHOD} = $tx->req->method;
    $env{SCRIPT_NAME}    = "";
    $env{PATH_INFO}      = $tx->req->url->path;
    $env{QUERY_STRING}   = $tx->req->url->query->to_string;
    $env{SERVER_NAME}    = $mojo_daemon->address;
    $env{SERVER_PORT}    = $mojo_daemon->port;
    $env{SERVER_PROTOCOL} = "HTTP/" . $tx->req->version;

    for my $name (@{ $tx->req->headers->names }) {
        $name =~ tr/-/_/;
        $env{"HTTP_" . uc($name)} = $tx->req->headers->header($name);
    }

    $env{CONTENT_TYPE}   = $tx->req->headers->content_type;
    $env{CONTENT_LENGTH} = $tx->req->headers->content_length;

    # FIXME: use IO::Handle-ish API
    my $content = $tx->req->content->asset->slurp;
    open my $input, "<", \$content;

    $env{'psgi.version'}    = [1,0];
    $env{'psgi.url_scheme'} = 'http';
    $env{'psgi.input'}      = $input;
    $env{'psgi.errors'}     = *STDERR;

    my $res = $self->psgi_app->(\%env);

    $tx->res->code($res->[0]);
    my $headers = $res->[1];
    while (my ($k, $v) = splice(@$headers, 0, 2)) {
        $tx->res->headers->header($k => $v);
    }

    my $body = $res->[2];

    # FIXME Use psgi.async API
    my $response_content;
    Plack::Util::foreach($body, sub { $response_content .= $_[0] });
    $tx->res->body($response_content);
}

package Plack::Impl::Mojo;

1;

__END__

=head1 NAME

Plack::Impl::Mojo - Mojo daemon based PSGI handler

=head1 SYNOPSIS

  use Plack::Impl::Mojo;

  my $server = Plack::Impl::Mojo->new(
      host => $host,
      port => $port,
  );
  $server->run($app);

=head1 DESCRIPTION

This implementation is considered highly experimental.

=cut
