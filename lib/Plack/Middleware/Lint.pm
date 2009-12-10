package Plack::Middleware::Lint;
use strict;
no warnings;
use Carp;
use parent qw(Plack::Middleware);

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
    if (scalar(@$res) == 3 && !ref($res)) {
        Carp::croak('third elements in response arrayref should be reference');
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

