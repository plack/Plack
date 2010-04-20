package Plack::Middleware::Lint;
use strict;
no warnings;
use Carp ();
use parent qw(Plack::Middleware);
use Scalar::Util qw(blessed);
use Plack::Util;

sub wrap {
    my($self, $app) = @_;

    unless (ref $app eq 'CODE' or overload::Method($app, '&{}')) {
        Carp::croak("PSGI app should be a code reference: ", (defined $app ? $app : "undef"));
    }

    $self->SUPER::wrap($app);
}

sub call {
    my $self = shift;
    my $env = shift;

    $self->validate_env($env);
    my $res = $self->app->($env);
    return $self->validate_res($res);
}

sub validate_env {
    my ($self, $env) = @_;
    unless ($env->{'REQUEST_METHOD'}) {
        Carp::croak('missing env param: REQUEST_METHOD');
    }
    unless ($env->{'REQUEST_METHOD'} =~ /^[A-Z]+$/) {
        Carp::croak("invalid env param: REQUEST_METHOD($env->{REQUEST_METHOD})");
    }
    unless (defined($env->{'SCRIPT_NAME'})) { # allows empty string
        Carp::croak('missing mandatory env param: SCRIPT_NAME');
    }
    unless (defined($env->{'PATH_INFO'})) { # allows empty string
        Carp::croak('missing mandatory env param: PATH_INFO');
    }
    unless (defined($env->{'SERVER_NAME'})) {
        Carp::croak('missing mandatory env param: SERVER_NAME');
    }
    unless ($env->{'SERVER_NAME'} ne '') {
        Carp::croak('SERVER_NAME must not be empty string');
    }
    unless (defined($env->{'SERVER_PORT'})) {
        Carp::croak('missing mandatory env param: SERVER_PORT');
    }
    unless ($env->{'SERVER_PORT'} ne '') {
        Carp::croak('SERVER_PORT must not be empty string');
    }
    unless (!defined($env->{'SERVER_PROTOCOL'}) || $env->{'SERVER_PROTOCOL'} =~ m{^HTTP/1.\d$}) {
        Carp::croak('invalid SERVER_PROTOCOL');
    }
    for my $param (qw/version url_scheme input errors multithread multiprocess/) {
        unless (exists $env->{"psgi.$param"}) {
            Carp::croak("missing psgi.$param");
        }
    }
    unless (ref($env->{'psgi.version'}) eq 'ARRAY') {
        Carp::croak('psgi.version should be ArrayRef');
    }
    unless (scalar(@{$env->{'psgi.version'}}) == 2) {
        Carp::croak('psgi.version should contain 2 elements');
    }
    unless ($env->{'psgi.url_scheme'} =~ /^https?$/) {
        Carp::croak('psgi.version should be "http" or "https"');
    }
    if ($env->{"psgi.version"}->[1] == 1) { # 1.1
        for my $param (qw(streaming nonblocking run_once)) {
            unless (exists $env->{"psgi.$param"}) {
                Carp::croak("missing psgi.$param");
            }
        }
    }
    if ($env->{HTTP_CONTENT_TYPE}) {
        Carp::croak('HTTP_CONTENT_TYPE should not exist');
    }
    if ($env->{HTTP_CONTENT_LENGTH}) {
        Carp::croak('HTTP_CONTENT_LENGTH should not exist');
    }
}

sub validate_res {
    my ($self, $res, $streaming) = @_;

    my $croak = $streaming ? \&Carp::confess : \&Carp::croak;

    unless (ref($res) and ref($res) eq 'ARRAY' || ref($res) eq 'CODE') {
        $croak->('response should be array ref or code ref');
    }

    if (ref $res eq 'CODE') {
        return $self->response_cb($res, sub { $self->validate_res(@_, 1) });
    }

    unless (@$res == 3 || ($streaming && @$res == 2)) {
        $croak->('response needs to be 3 element array, or 2 element in streaming');
    }

    unless ($res->[0] =~ /^\d+$/ && $res->[0] >= 100) {
        $croak->('status code needs to be an integer greater than or equal to 100');
    }

    unless (ref $res->[1] eq 'ARRAY') {
        $croak->('Headers needs to be an array ref');
    }

    # @$res == 2 is only right in psgi.streaming, and it's already checked.
    unless (@$res == 2 ||
            ref $res->[2] eq 'ARRAY' ||
            Plack::Util::is_real_fh($res->[2]) ||
            (blessed($res->[2]) && $res->[2]->can('getline'))) {
        $croak->('body should be an array ref or filehandle');
    }

    if (ref $res->[2] eq 'ARRAY' && grep utf8::is_utf8($_), @{$res->[2]}) {
        $croak->('body must be bytes and should not contain wide characters (UTF-8 strings).');
    }

    return $res;
}

1;
__END__

=head1 NAME

Plack::Middleware::Lint - Validate request and response

=head1 SYNOPSIS

  use Plack::Middleware::Lint;

  my $app = sub { ... }; # your app or middleware
  $app = Plack::Middleware::Lint->wrap($app);

  # Or from plackup
  plackup -e 'enable "Lint"' myapp.psgi

=head1 DESCRIPTION

Plack::Middleware::Lint is a middleware component to validate request
and response environment formats. You are strongly suggested to use
this middleware when you develop a new framework adapter or a new PSGI
web server that implements the PSGI interface.

This middleware is enabled by default when you run plackup or other
launcher tools with the default environment I<development> value.

=head1 AUTHOR

Tatsuhiko Miyagawa

Tokuhiro Matsuno

=head1 SEE ALSO

L<Plack>

=cut

