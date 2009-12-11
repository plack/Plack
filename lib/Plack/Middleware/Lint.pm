package Plack::Middleware::Lint;
use strict;
no warnings;
use Carp ();
use parent qw(Plack::Middleware);
use Scalar::Util qw(blessed);
use Plack::Util;

sub call {
    my $self = shift;
    my $env = shift;

    $self->validate_env($env);
    my $res = $self->app->($env);
    $self->validate_res($res);
    return $res;
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
    for my $param (qw/version url_scheme input errors/) {
        unless (defined($env->{"psgi.$param"})) {
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
}

sub validate_res {
    my ($self, $res) = @_;

    unless (ref($res) and ref($res) eq 'ARRAY' || ref($res) eq 'CODE') {
        Carp::croak('response should be arrayref or coderef');
    }

    return unless ref $res eq 'ARRAY';

    unless (@$res == 3) {
        Carp::croak('response needs to be 3 element array');
    }

    unless ($res->[0] =~ /^\d+$/ && $res->[0] >= 100) {
        Carp::croak('status code needs to be an integer greater than or equal to 100');
    }

    unless (ref $res->[1] eq 'ARRAY') {
        Carp::croak('Headers needs to be an array ref');
    }

    unless (ref $res->[2] eq 'ARRAY' ||
            Plack::Util::is_real_fh($res->[2]) ||
            (blessed($res->[2]) && $res->[2]->can('getline'))) {
        Carp::croak('body should be an array ref or filehandle');
    }

    if (ref $res->[2] eq 'ARRAY' && grep utf8::is_utf8($_), @{$res->[2]}) {
        Carp::croak('body must be bytes and should not contain wide characters (UTF-8 strings).');
    }
}

1;
__END__

=head1 NAME

Plack::Middleware::Lint - Validate request and response

=head1 SYNOPSIS

  use Plack::Middleware::Lint;

  my $app = sub { ... }; # your app or middleware
  $app = Plack::Middleware::Lint->wrap($app);

=head1 DESCRIPTION

Plack::Middleware::Lint is a middleware to validate request and
response environment. Handy to validate missing parameters etc. when
writing a server or middleware.

=head1 AUTHOR

Tokuhiro Matsuno

=cut

