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
        die("PSGI app should be a code reference: ", (defined $app ? $app : "undef"));
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
    unless ($env->{REQUEST_METHOD}) {
        die('Missing env param: REQUEST_METHOD');
    }
    unless ($env->{REQUEST_METHOD} =~ /^[A-Z]+$/) {
        die("Invalid env param: REQUEST_METHOD($env->{REQUEST_METHOD})");
    }
    unless (defined($env->{SCRIPT_NAME})) { # allows empty string
        die('Missing mandatory env param: SCRIPT_NAME');
    }
    if ($env->{SCRIPT_NAME} eq '/') {
        die('SCRIPT_NAME must not be /');
    }
    unless (defined($env->{PATH_INFO})) { # allows empty string
        die('Missing mandatory env param: PATH_INFO');
    }
    if ($env->{PATH_INFO} ne '' && $env->{PATH_INFO} !~ m!^/!) {
        die('PATH_INFO must begin with / ($env->{PATH_INFO})');
    }
    unless (defined($env->{SERVER_NAME})) {
        die('Missing mandatory env param: SERVER_NAME');
    }
    if ($env->{SERVER_NAME} eq '') {
        die('SERVER_NAME must not be empty string');
    }
    unless (defined($env->{SERVER_PORT})) {
        die('Missing mandatory env param: SERVER_PORT');
    }
    if ($env->{SERVER_PORT} eq '') {
        die('SERVER_PORT must not be empty string');
    }
    if (defined($env->{SERVER_PROTOCOL}) and $env->{SERVER_PROTOCOL} !~ m{^HTTP/1.\d$}) {
        die("Invalid SERVER_PROTOCOL: $env->{SEREVR_PROTOCOL}");
    }
    for my $param (qw/version url_scheme input errors multithread multiprocess/) {
        unless (exists $env->{"psgi.$param"}) {
            die("Missing psgi.$param");
        }
    }
    unless (ref($env->{'psgi.version'}) eq 'ARRAY') {
        die("psgi.version should be ArrayRef: $env->{'psgi.version'}");
    }
    unless (scalar(@{$env->{'psgi.version'}}) == 2) {
        die('psgi.version should contain 2 elements, not ', scalar(@{$env->{'psgi.version'}}));
    }
    unless ($env->{'psgi.url_scheme'} =~ /^https?$/) {
        die("psgi.url_scheme should be 'http' or 'https': ", $env->{'psgi.url_scheme'});
    }
    if ($env->{"psgi.version"}->[1] == 1) { # 1.1
        for my $param (qw(streaming nonblocking run_once)) {
            unless (exists $env->{"psgi.$param"}) {
                die("Missing psgi.$param");
            }
        }
    }
    if ($env->{HTTP_CONTENT_TYPE}) {
        die('HTTP_CONTENT_TYPE should not exist');
    }
    if ($env->{HTTP_CONTENT_LENGTH}) {
        die('HTTP_CONTENT_LENGTH should not exist');
    }
}

sub is_possibly_fh {
    my $fh = shift;

    ref $fh eq 'GLOB' &&
    *{$fh}{IO} &&
    *{$fh}{IO}->can('getline');
}

sub validate_res {
    my ($self, $res, $streaming) = @_;

    unless (ref($res) eq 'ARRAY' or ref($res) eq 'CODE') {
        die("Response should be array ref or code ref: $res");
    }

    if (ref $res eq 'CODE') {
        return $self->response_cb($res, sub { $self->validate_res(@_, 1) });
    }

    unless (@$res == 3 || ($streaming && @$res == 2)) {
        die('Response needs to be 3 element array, or 2 element in streaming');
    }

    unless ($res->[0] =~ /^\d+$/ && $res->[0] >= 100) {
        die("Status code needs to be an integer greater than or equal to 100: $res->[0]");
    }

    unless (ref $res->[1] eq 'ARRAY') {
        die("Headers needs to be an array ref: $res->[1]");
    }

    my @copy = @{$res->[1]};
    unless (@copy % 2 == 0) {
        die('The number of response headers needs to be even, not odd(', scalar(@copy), ')');
    }

    while(my($key, $val) = splice(@copy, 0, 2)) {
        if (lc $key eq 'status') {
            die('Response headers MUST NOT contain a key named Status');
        }
        if ($key =~ /[:\r\n]|[-_]$/) {
            die("Response headers MUST NOT contain a key with : or newlines, or that end in - or _: $key");
        }
        unless ($key =~ /^[a-zA-Z][0-9a-zA-Z\-_]*$/) {
            die("Response headers MUST consist only of letters, digits, _ or - and MUST start with a letter: $key");
        }
        if ($val =~ /[\000-\037]/) {
            die("Response headers MUST NOT contain characters below octal \037: $val");
        }
        if (!defined $val) {
            die("Response headers MUST be a defined string");
        }
    }

    # @$res == 2 is only right in psgi.streaming, and it's already checked.
    unless (@$res == 2 ||
            ref $res->[2] eq 'ARRAY' ||
            Plack::Util::is_real_fh($res->[2]) ||
            is_possibly_fh($res->[2]) ||
            (blessed($res->[2]) && $res->[2]->can('getline'))) {
        die("Body should be an array ref or filehandle: $res->[2]");
    }

    if (ref $res->[2] eq 'ARRAY' && grep _has_wide_char($_), @{$res->[2]}) {
        die("Body must be bytes and should not contain wide characters (UTF-8 strings)");
    }

    return $res;
}

# NOTE: Some modules like HTML:: or XML:: could possibly generate
# ASCII/Latin-1 strings with utf8 flags on. They're actually safe to
# print, so there's no need to give warnings about it.
sub _has_wide_char {
    my $str = shift;
    utf8::is_utf8($str) && $str =~ /[^\x00-\xff]/;
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

=head1 DEBUGGING

Because of how this middleware works, it may not be easy to debug Lint
errors when you encounter one, unless you're writing a PSGI web server
or a framework.

For example, when you're an application developer (user of some
framework) and see errors like:

  Body should be an array ref or filehandle at lib/Plack/Middleware/Lint.pm line XXXX

there's no clue about which line of I<your application> produces that
error.

We're aware of the issue, and have a plan to spit out more helpful
errors to diagnose the issue. But until then, currently there are some
workarounds to make this easier. For now, the easiest one would be to
enable L<Plack::Middleware::REPL> outside of the Lint middleware,
like:

  plackup -e 'enable "REPL"; enable "Lint"' app.psgi

so that the Lint errors are caught by the REPL shell, where you can
inspect all the variables in the response.

=head1 AUTHOR

Tatsuhiko Miyagawa

Tokuhiro Matsuno

=head1 SEE ALSO

L<Plack>

=cut

