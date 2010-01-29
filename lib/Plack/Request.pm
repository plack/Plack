package Plack::Request;
use strict;
use warnings;
use 5.008_001;
our $VERSION = "0.09";

use HTTP::Headers;
use Carp ();
use Hash::MultiValue;
use HTTP::Body;

use Plack::Request::Upload;
use Plack::TempBuffer;
use URI;
use URI::Escape ();

sub _deprecated {
    my $alt = shift;
    my $method = (caller(1))[3];
    Carp::carp("$method is deprecated. Use '$alt' instead.");
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

    return {} unless $self->env->{HTTP_COOKIE};

    # HTTP_COOKIE hasn't changed: reuse the parsed cookie
    if (   $self->env->{'plack.cookie.parsed'}
        && $self->env->{'plack.cookie.string'} eq $self->env->{HTTP_COOKIE}) {
        return $self->env->{'plack.cookie.parsed'};
    }

    $self->env->{'plack.cookie.string'} = $self->env->{HTTP_COOKIE};

    my %results;
    my @pairs = split "[;,] ?", $self->env->{'plack.cookie.string'};
    for my $pair ( @pairs ) {
        # trim leading trailing whitespace
        $pair =~ s/^\s+//; $pair =~ s/\s+$//;

        my ($key, $value) = map URI::Escape::uri_unescape($_), split( "=", $pair, 2 );

        # Take the first one like CGI.pm or rack do
        $results{$key} = $value unless exists $results{$key};
    }

    $self->env->{'plack.cookie.parsed'} = \%results;
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

    my $fh = $self->env->{'plack.request.tempfh'} or return '';
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

sub hostname     { _deprecated 'remote_host';      $_[0]->remote_host || $_[0]->address }
sub url_scheme   { _deprecated 'scheme';           $_[0]->scheme }
sub raw_body     { _deprecated 'content';          $_[0]->content }
sub params       { _deprecated 'parameters';       shift->parameters(@_) }
sub query_params { _deprecated 'query_parameters'; shift->query_parameters(@_) }
sub body_params  { _deprecated 'body_parameters';  shift->body_parameters(@_) }

sub cookie {
    my $self = shift;
    _deprecated 'cookies';

    return keys %{ $self->cookies } if @_ == 0;

    my $name = shift;
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
    _deprecated 'base';

    my $base = $self->base;
    $base->path_query($self->env->{REQUEST_URI});

    $base;
}

sub uri {
    my $self = shift;
    ( $self->env->{'plack.request.uri'} ||= $self->_uri )->clone;
}

sub base {
    my $self = shift;
    ( $self->env->{'plack.request.base'} ||= $self->_uri_base )->clone;
}

sub _uri_base {
    my $self = shift;

    my $env = $self->env;

    my $uri = ($env->{'psgi.url_scheme'} || "http") .
        "://" .
        ($env->{HTTP_HOST} || (($env->{SERVER_NAME} || "") . ":" . ($env->{SERVER_PORT} || 80))) .
        ($env->{SCRIPT_NAME} || '/');

    return URI->new($uri)->canonical;
}

sub _uri {
    my $self = shift;

    my $uri = $self->base;

    my $path = $uri->path;
    $path .= $self->env->{PATH_INFO} || '';
    $path =~ s{^/+}{};
    $path .= '?' . $self->env->{QUERY_STRING}
        if defined $self->env->{QUERY_STRING} && $self->env->{QUERY_STRING} ne '';

    $uri->path_query("/" . $path);
    $uri->canonical;
}

sub path {
    _deprecated 'uri->path';
    shift->uri->path(@_);
}

sub new_response {
    my $self = shift;
    require Plack::Response;
    Plack::Response->new(@_);
}

sub _parse_request_body {
    my $self = shift;

    my $ct = $self->env->{CONTENT_TYPE};
    my $cl = $self->env->{CONTENT_LENGTH};
    if (!$ct && !$cl) {
        # No Content-Type nor Content-Length -> GET/HEAD
        $self->env->{'plack.request.body'}   = Hash::MultiValue->new;
        $self->env->{'plack.request.upload'} = Hash::MultiValue->new;
        return;
    }

    # Do not use ->content_type to get multipart boundary correctly
    my $body = HTTP::Body->new($ct, $cl);

    my $input = $self->input;

    my $buffer;
    unless ($self->env->{'plack.request.tempfh'}) {
        $buffer = Plack::TempBuffer->new($cl);
    }

    my $spin = 0;
    while ($cl) {
        $input->read(my $chunk, $cl < 8192 ? $cl : 8192);
        my $read = length $chunk;
        $cl -= $read;
        $body->add($chunk);
        $buffer->print($chunk) if $buffer;

        if ($read == 0 && $spin++ > 2000) {
            Carp::croak "Bad Content-Length: maybe client disconnect? ($cl bytes remaining)";
        }
    }

    if ($buffer) {
        $self->env->{'plack.request.tempfh'} = $self->env->{'psgi.input'} = $buffer->rewind;
    }

    $self->env->{'plack.request.body'}   = Hash::MultiValue->from_mixed($body->param);

    my @uploads = Hash::MultiValue->from_mixed($body->upload)->flatten;
    my @obj;
    while (my($k, $v) = splice @uploads, 0, 2) {
        push @obj, $k, $self->_make_upload($v);
    }

    $self->env->{'plack.request.upload'} = Hash::MultiValue->new(@obj);

    1;
}

sub _make_upload {
    my($self, $upload) = @_;
    Plack::Request::Upload->new(
        headers => HTTP::Headers->new( %{delete $upload->{headers}} ),
        %$upload,
    );
}

1;
__END__

=head1 NAME

Plack::Request - Portable HTTP request object from PSGI env hash

=head1 SYNOPSIS

  use Plack::Request;

  my $app_or_middleware = sub {
      my $env = shift; # PSGI env

      my $req = Plack::Request->new($env);

      my $path_info = $req->path_info;
      my $query     = $req->param('query');

      my $res = $req->new_response(200); # new Plack::Response
      $res->finalize;
  };

=head1 DESCRIPTION

L<Plack::Request> provides a consistent API for request objects across
web server environments.

=head1 CAVEAT

Note that this module is intended to be used by Plack middleware
developers and web application framework developers rather than
application developers (end users).

Writing your web application directly using Plack::Request is
certainly possible but not recommended: it's like doing so with
mod_perl's Apache::Request: yet too low level.

If you're writing a web application, not a framework, then you're
encouraged to use one of the web application frameworks that support
PSGI, or see L<Piglet> or L<HTTP::Engine> to provide higher level
Request and Response API on top of PSGI.

=head1 METHODS

Some of the methods defined in the earlier versions are deprecated in
version 1.00. Take a look at L</"INCOMPATIBILITIES">.

Unless otherwise noted, all methods and attribtues are B<read-only>,
and passing values to the method like an accessor doesn't work like
you expect it to.

=head2 new

    Plack::Request->new( $env );

Creates a new request object.

=head1 ATTRIBUTES

=over 4

=item env

Returns the shared PSGI environment hash reference. This is a
reference, so writing to this environment passes through during the
whole PSGI request/response cycle.

=item address

Returns the IP address of the client (C<REMOTE_ADDR>).

=item remote_host

Returns the remote host (C<REMOTE_HOST>) of the client. It may be
empty, in which case you have to get the IP address using C<address>
method and resolve by your own.

=item method

Contains the request method (C<GET>, C<POST>, C<HEAD>, etc).

=item protocol

Returns the protocol (HTTP/1.0 or HTTP/1.1) used for the current request.

=item request_uri

Returns the raw, undecoded request URI path. You probably do B<NOT>
want to use this to dispatch requests.

=item path_info

Returns B<PATH_INFO> in the environment. Use this to get the local
path for the requests.

=item script_name

Returns B<SCRIPT_NAME> in the environment. This is the absolute path
where your application is hosted.

=item scheme

Returns the scheme (C<http> or C<https>) of the request.

=item secure

Returns true or false, indicating whether the connection is secure (https).

=item body, input

Returns C<psgi.input> handle.

=item session

Returns (optional) C<psgix.session> hash. When it exists, you can
retrieve and store per-session data from and to this hash.

=item session_options

Returns (optional) C<psgix.session.options> hash.

=item logger

Returns (optional) C<psgix.logger> code reference. When it exists,
your application is supposed to send the log message to this logger,
using:

  $req->logger->({ level => 'debug', message => "This is a debug message" });

=item cookies

Returns a reference to a hash containing the cookies. Values are
strings that are sent by clients and are URI decoded.

=item query_parameters

Returns a reference to a hash containing query string (GET)
parameters. This hash reference is L<Hash::MultiValue> object, which
means you can use it as a plain hash where values are always scalars
(B<NOT> array reference) but can call:

  my @foo = $req->query_parameters->get_all('foo');

to get multiple values with the same key. See L<Hash::MultiValue> for
details.

=item body_parameters

Returns a reference to a hash containing posted parameters in the
request body (POST). Similarly to C<query_parameters>, the hash
reference is a L<Hash::MultiValue> object.

=item parameters

Returns a L<Hash::MultiValue> hash reference containing (merged) GET
and POST parameters.

=item content

Returns the request content in an undecoded byte string.

=item uri

Returns an URI object for the current request. The URI is constructed
using various environment values such as C<SCRIPT_NAME>, C<PATH_INFO>,
C<QUERY_STRING>, C<HTTP_HOST>, C<SERVER_NAME> and C<SERVER_PORT>.

Every time this method is called it returns a new, cloned URI object.

=item base

Retutrns an URI object for the base path of current request. This is
like C<uri> but only contains up to C<SCRIPT_NAME> where your
application is hosted at.

Every time this method is called it returns a new, cloned URI object.

=item user

Returns C<REMOTE_USER> if it's set.

=item headers

Returns an L<HTTP::Headers> object containing the headers for the current request.

=item uploads

Returns a reference to a hash containing uploads. The hash reference
is L<Hash::MultiValue> object and values are L<Plack::Request::Upload>
objects.

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

=item param

Returns GET and POST parameters with a CGI.pm-compatible param
method. This is an alternative method for accessing parameters in
$req->parameters.

    $value  = $req->param( 'foo' );
    @values = $req->param( 'foo' );
    @params = $req->param;

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

=head2 PARSING POST BODY and MULTIPLE OBJECTS

These methods (C<content>, C<body_parameters> and C<uploads>) are
carefully coded to save the parsed body in the environment hash as
well as in the temporary buffer, so you can call them multiple times
and create Plack::Request objects multiple times in a request and they
should work nicely.

=head1 INCOMPATIBILITIES

In version 1.0, many utility methods are removed or deprecated, and
most methods are made read-only.

The following methods are deprecated: C<hostname>, C<url_scheme>,
C<raw_body>, C<params>, C<query_params>, C<body_params>, C<cookie>,
C<raw_uri> and C<path>. They will be removed in the next major release.

All parameter-related methods such as C<parameters>,
C<body_parameters>, C<query_parameters> and C<uploads> now contains
L<Hash::MultiValue> objects, rather than I<scalar or an array
reference depending on the user input> which is unsecure. See
L<Hash::MultiValue> for more about this change.

Cookie handling is simplified, and doesn't use L<CGI::Simple::Cookie>
anymore, which means you B<CAN NOT> set array reference or hash
reference as a cookie value. You're always required to set string
value, and encoding or decoding them is totally up to your application
(or framework).

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
