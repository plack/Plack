package Plack::Lint;
use strict;
no warnings;
use Carp;

sub wrap {
    my $class = shift;
    my $app = shift;

    return sub {
        my $env = shift;
        $class->validate_env($env);
        my $res = $app->($env);
        $class->validate_res($res);
        return $res;
    };
}

sub validate_env {
    my ($class, $env) = @_;
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
    my ($class, $res) = @_;
    unless (ref($res) && ref($res) eq 'ARRAY') {
        Carp::croak('response should be arrayref');
    }
    if (scalar(@$res) == 3 && !ref($res)) {
        Carp::croak('third elements in response arrayref should be reference');
    }
}

1;
__END__
