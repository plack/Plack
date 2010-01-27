package Plack::Request;
use strict;
use warnings;
use 5.008_001;
our $VERSION = "0.09";

use HTTP::Headers;
use Carp ();
use Hash::MultiValue;
use HTTP::Body;
use IO::File;

use Plack::Request::Upload;
use URI;

sub _deprecated {
    my $self = shift;
    my $method = (caller(1))[3];
    Carp::carp("$method is deprecated. Use Piglet::Request instead.");
}

sub new {
    my($class, $env) = @_;
    Carp::croak(q{$env is required})
        unless defined $env && ref($env) eq 'HASH';

    bless { env => $env }, $class;
}

sub env { $_[0]->{env} }

sub address     { $_[0]->env->{REMOTE_ADDR} }
sub remote_host { $_[0]->env->{REMOTE_HOST} }
sub protocol    { $_[0]->env->{SERVER_PROTOCOL} }
sub method      { $_[0]->env->{REQUEST_METHOD} }
sub port        { $_[0]->env->{SERVER_PORT} }
sub user        { $_[0]->env->{REMOTE_USER} }
sub request_uri { $_[0]->env->{REQUEST_URI} }
sub path_info   { $_[0]->env->{PATH_INFO} }
sub script_name { $_[0]->env->{SCRIPT_NAME} }
sub scheme      { $_[0]->env->{'psgi.url_scheme'} }
sub secure      { $_[0]->scheme eq 'https' }
sub body        { $_[0]->env->{'psgi.input'} }
sub input       { $_[0]->env->{'psgi.input'} }

sub session         { $_[0]->env->{'psgix.session'} }
sub session_options { $_[0]->env->{'psgix.session.options'} }
sub logger          { $_[0]->env->{'psgix.logger'} }

sub cookies {
    my $self = shift;

    $self->env->{'plack.cookie.parsed'} ||= do {
        my $header = $self->header('Cookie');
        +{ CGI::Simple::Cookie->parse($header) };
    };
}

sub query_parameters {
    my $self = shift;
    $self->env->{'plack.request.query'} ||= Hash::MultiValue->new($self->uri->query_form);
}

sub content {
    my $self = shift;

    unless ($self->env->{'plack.request.tempfh'}) {
        $self->_parse_request_body;
    }

    my $fh = $self->env->{'plack.request.tempfh'};
    $fh->read(my($content), $self->content_length);
    $fh->seek(0, 0);

    return $content;
}

sub headers {
    my $self = shift;
    if (!defined $self->{headers}) {
        my $env = $self->env;
        $self->{headers} = HTTP::Headers->new(
            map {
                (my $field = $_) =~ s/^HTTPS?_//;
                ( $field => $env->{$_} );
            }
                grep { /^(?:HTTP|CONTENT|COOKIE)/i } keys %$env
            );
    }
    $self->{headers};
}
# shortcut
sub content_encoding { shift->headers->content_encoding(@_) }
sub content_length   { shift->headers->content_length(@_) }
sub content_type     { shift->headers->content_type(@_) }
sub header           { shift->headers->header(@_) }
sub referer          { shift->headers->referer(@_) }
sub user_agent       { shift->headers->user_agent(@_) }

sub body_parameters {
    my $self = shift;

    unless ($self->env->{'plack.request.body'}) {
        $self->_parse_request_body;
    }

    return $self->env->{'plack.request.body'};
}

# contains body + query
sub parameters {
    my $self = shift;

    $self->env->{'plack.request.merged'} ||= do {
        my $query = $self->query_parameters;
        my $body  = $self->body_parameters;
        Hash::MultiValue->new($query->flatten, $body->flatten);
    };
}

sub uploads {
    my $self = shift;

    if ($self->env->{'plack.request.upload'}) {
        return $self->env->{'plack.request.upload'};
    }

    $self->_parse_request_body;
    return $self->env->{'plack.request.upload'};
}

sub hostname     { _deprecated; $_[0]->remote_host || $_[0]->address }
sub url_scheme   { _deprecated; $_[0]->scheme }
sub raw_body     { _deprecated; $_[0]->content }
sub params       { _deprecated; shift->parameters(@_) }
sub query_params { _deprecated; shift->query_parameters(@_) }
sub body_params  { _deprecated; shift->body_parameters(@_) }

sub cookie {
    my $self = shift;

    return keys %{ $self->cookies } if @_ == 0;

    my $name = shift;
    return undef unless exists $self->cookies->{$name}; ## no critic.
    return $self->cookies->{$name};
}

sub param {
    my $self = shift;

    return keys %{ $self->parameters } if @_ == 0;

    my $key = shift;
    return $self->parameters->{$key} unless wantarray;
    return $self->parameters->get_all($key);
}

sub upload {
    my $self = shift;

    return keys %{ $self->uploads } if @_ == 0;

    my $key = shift;
    return $self->uploads->{$key} unless wantarray;
    return $self->uploads->get_all($key);
}

sub raw_uri {
    my $self = shift;

    my $env    = $self->env;
    my $scheme = $env->{'psgi.url_scheme'} || "http";

    # Host header should contain port number as well
    my $host = $env->{HTTP_HOST} || do {
        my $port   = $env->{SERVER_PORT} || 80;
        my $is_std_port = ($scheme eq 'http' && $port == 80) || ($scheme eq 'https' && $port == 443);
        $env->{SERVER_NAME} . ($is_std_port ? "" : ":$port");
    };

    my $uri = "$scheme\://$host" . $env->{REQUEST_URI};
    return URI->new($uri);
}

sub base {
    my $self = shift;

    my $uri = $self->raw_uri;
    $uri->path_query($self->env->{SCRIPT_NAME} || "/");

    return $uri;
}

sub uri {
    my $self = shift;
    $self->env->{'plack.request.uri'} ||= $self->_build_uri;
}

sub _build_uri  {
    my $self = shift;

    my $env = $self->env;
    my $base_path = $env->{SCRIPT_NAME} || '/';

    my $path = $base_path . ($env->{PATH_INFO} || '');
    $path =~ s{^/+}{};

    my $uri = ($env->{'psgi.url_scheme'} || "http") .
        "://" .
        ($env->{HTTP_HOST} || (($env->{SERVER_NAME} || "") . ":" . ($env->{SERVER_PORT} || 80))) .
        "/" .
        ($path || "") .
        ($env->{QUERY_STRING} ? "?$env->{QUERY_STRING}" : "");

    # sanitize the URI
    return URI->new($uri)->canonical;
}

sub path {
    _deprecated;
    shift->uri->path(@_);
}

sub new_response {
    my $self = shift;
    require Plack::Response;
    Plack::Response->new(@_);
}

sub _parse_request_body {
    my $self = shift;

    # Do not use ->content_type to get multipart boundary correctly
    my $body = HTTP::Body->new($self->env->{CONTENT_TYPE}, $self->env->{CONTENT_LENGTH});
    my $cl = $self->content_length;

    my $input = $self->input;

    my $fh;
    unless ($self->env->{'plack.request.tempfh'}) {
        $fh = IO::File->new_tmpfile;
        binmode $fh;
    }

    my $spin = 0;
    while ($cl) {
        $input->read(my $buffer, $cl < 8192 ? $cl : 8192);
        my $read = length $buffer;
        $cl -= $read;
        $body->add($buffer);
        $fh->print($buffer) if $fh;

        if ($read == 0 && $spin++ > 2000) {
            Carp::croak "Bad Content-Length: maybe client disconnect? ($cl bytes remaining)";
        }
    }

    if ($fh) {
        $fh->seek(0, 0);
        $self->env->{'plack.request.tempfh'} = $self->env->{'psgi.input'} = $fh;
    }

    $self->env->{'plack.request.body'}   = Hash::MultiValue->from_mixed($body->param);
    $self->env->{'plack.request.upload'} = $self->_normalize_multi($body->upload, sub { $self->_make_upload(@_) });

    1;
}

sub _make_upload {
    my($self, $upload) = @_;
    Plack::Request::Upload->new(
        headers => HTTP::Headers->new( %{delete $upload->{headers}} ),
        %$upload,
    );
}

sub _normalize_multi {
    my($self, $hash, $cb) = @_;

    my @new;
    while (my($key, $val) = each %$hash) {
        my @val = ref $val eq 'ARRAY' ? @$val : ($val);
        for my $val (@val) {
            $val = $cb->($val) if $cb;
            push @new, $key, $val;
        }
    }

    return Hash::MultiValue->new(@new);
}

1;
__END__

=head1 NAME

Plack::Request - Portable HTTP request object from PSGI env hash

=head1 SYNOPSIS

  use Plack::Request;

  my $env = shift; # PSGI env
  my $req = Plack::Request->new($env);

  my $path_info = $req->path_info;
  my $query     = $req->param('query');

  my $res = $req->new_response(200); # new Plack::Response

=head1 DESCRIPTION

L<Plack::Request> provides a consistent API for request objects across
web server environments.

=head1 CAVEAT

Note that this module is intended to be used by web application
framework developers rather than application developers (end
users). Writing your web application directly using Plack::Request is
certainly possible but not recommended: it's like doing so with
mod_perl's Apache::Request: yet too low level.

If you're writing a web application, not a framework, then you're
encouraged to use one of the web application frameworks that support
PSGI, or use L<HTTP::Engine> if you want to write a micro web server
application.

Also, even if you're a framework developer, you probably want to
handle Cookies and file uploads in your own way: Plack::Request gives
you a simple API to deal with these things but ultimately you probably
want to implement those in your own code.

=head1 METHODS

=head2 new

    Plack::Request->new( $psgi_env );

=head1 ATTRIBUTES

=over 4

=item address

Returns the IP address of the client.

=item cookies

Returns a reference to a hash containing the cookies

=item method

Contains the request method (C<GET>, C<POST>, C<HEAD>, etc).

=item protocol

Returns the protocol (HTTP/1.0 or HTTP/1.1) used for the current request.

=item request_uri

Returns the raw request URI.

=item query_parameters

Returns a reference to a hash containing query string (GET)
parameters. Values can be either a scalar or an arrayref containing
scalars.

=item secure

Returns true or false, indicating whether the connection is secure (https).

=item uri

Returns an URI object for the current request. Stringifies to the URI text.

=item user

Returns REMOTE_USER.

=item raw_body

Returns string containing body(POST).

=item headers

Returns an L<HTTP::Headers> object containing the headers for the current request.

=item hostname

Returns the hostname of the client.

=item parameters

Returns a reference to a hash containing GET and POST parameters. Values can
be either a scalar or an arrayref containing scalars.

=item uploads

Returns a reference to a hash containing uploads. Values can be either a
L<Plack::Request::Upload> object, or an arrayref of
L<Plack::Request::Upload> objects.

=item content_encoding

Shortcut to $req->headers->content_encoding.

=item content_length

Shortcut to $req->headers->content_length.

=item content_type

Shortcut to $req->headers->content_type.

=item header

Shortcut to $req->headers->header.

=item referer

Shortcut to $req->headers->referer.

=item user_agent

Shortcut to $req->headers->user_agent.

=item cookie

A convenient method to access $req->cookies.

    $cookie  = $req->cookie('name');
    @cookies = $req->cookie;

=item param

Returns GET and POST parameters with a CGI.pm-compatible param method. This 
is an alternative method for accessing parameters in $req->parameters.

    $value  = $req->param( 'foo' );
    @values = $req->param( 'foo' );
    @params = $req->param;

=item path

Returns the path, i.e. the part of the URI after $req->base, for the current request.

=item upload

A convenient method to access $req->uploads.

    $upload  = $req->upload('field');
    @uploads = $req->upload('field');
    @fields  = $req->upload;

    for my $upload ( $req->upload('field') ) {
        print $upload->filename;
    }

=item new_response

  my $res = $req->new_response;

Creates a new L<Plack::Response> object. Handy to remove dependency on
L<Plack::Response> in your code for easy subclassing and duck typing
in web application frameworks, as well as overriding Response
generation in middlewares.

=back

=head1 AUTHORS

Tatsuhiko Miyagawa

Kazuhiro Osawa

Tokuhiro Matsuno

=head1 SEE ALSO

L<Plack::Response> L<HTTP::Request>, L<Catalyst::Request>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
