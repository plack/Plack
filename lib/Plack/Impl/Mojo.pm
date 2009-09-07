package Plack::Impl::Mojo;
use strict;
use warnings;
use base qw(Mojo);
use Plack::Util;

__PACKAGE__->attr([ 'psgi_app' ]);

my $mojo_daemon;

sub start {
    my($class, $daemon, $app) = @_;
    $mojo_daemon = $daemon; # xxx
    $daemon->app($class->new);
    $daemon->app->psgi_app($app);
    $daemon->run;
}

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

    # XXX Oops
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
    my $response_content; # Hmm
    Plack::Util::foreach($body, sub { $response_content .= $_[0] });
    $tx->res->body($response_content);
}

1;

__END__

=head1 NAME

Plack::Impl::Mojo - Mojo daemon based PSGI handler

=head1 SYNOPSIS

  use Mojo::Server::Daemon;
  use Plack::Impl::Mojo;

  my $daemon = Mojo::Server::Daemon->new;
  Plack::Impl::Mojo->start($daemon, sub {
      my $env = shift;
      return [
          200,
          [ 'Content-Type' => 'text/html' ],
          [ 'Hello World' ],
      ];
  });
