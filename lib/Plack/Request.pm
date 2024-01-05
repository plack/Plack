package Plack::Request;
use strict;
use warnings;
use 5.008_001;
our $VERSION = '1.0051';

use HTTP::Headers::Fast;
use Carp ();
use Hash::MultiValue;

use Plack::Request::Upload;
use Stream::Buffered;
use URI;
use URI::Escape ();
use Cookie::Baker ();

use HTTP::Entity::Parser;
use WWW::Form::UrlEncoded qw/parse_urlencoded_arrayref/;

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
sub path        { $_[0]->env->{PATH_INFO} || '/' }
sub query_string{ $_[0]->env->{QUERY_STRING} }
sub script_name { $_[0]->env->{SCRIPT_NAME} }
sub scheme      { $_[0]->env->{'psgi.url_scheme'} }
sub secure      { $_[0]->scheme eq 'https' }
sub body        { $_[0]->env->{'psgi.input'} }
sub input       { $_[0]->env->{'psgi.input'} }

sub content_length   { $_[0]->env->{CONTENT_LENGTH} }
sub content_type     { $_[0]->env->{CONTENT_TYPE} }

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
    $self->env->{'plack.cookie.parsed'} = Cookie::Baker::crush_cookie($self->env->{'plack.cookie.string'});
}

sub content {
    my $self = shift;

    unless ($self->env->{'psgix.input.buffered'}) {
        $self->_parse_request_body;
    }

    my $fh = $self->input                 or return '';
    my $cl = $self->env->{CONTENT_LENGTH} or return '';

    $fh->seek(0, 0); # just in case middleware/apps read it without seeking back
    $fh->read(my($content), $cl, 0);
    $fh->seek(0, 0);

    return $content;
}

sub raw_body { $_[0]->content }

# XXX you can mutate headers with ->headers but it's not written through to the env

sub headers {
    my $self = shift;
    if (!defined $self->{headers}) {
        my $env = $self->env;
        $self->{headers} = HTTP::Headers::Fast->new(
            map {
                (my $field = $_) =~ s/^HTTPS?_//;
                ( lc($field) => $env->{$_} );
            }
                grep { /^(?:HTTP|CONTENT)_/ } keys %$env
            );
    }
    $self->{headers};
}

sub content_encoding { shift->headers->content_encoding(@_) }
sub header           { shift->headers->header(@_) }
sub referer          { shift->headers->referer(@_) }
sub user_agent       { shift->headers->user_agent(@_) }

sub _body_parameters {
    my $self = shift;
    unless ($self->env->{'plack.request.body_parameters'}) {
        $self->_parse_request_body;
    }
    return $self->env->{'plack.request.body_parameters'};
}

sub _query_parameters {
    my $self = shift;
    $self->env->{'plack.request.query_parameters'} ||= parse_urlencoded_arrayref($self->env->{'QUERY_STRING'});
}

sub query_parameters {
    my $self = shift;
    $self->env->{'plack.request.query'} ||= Hash::MultiValue->new(@{$self->_query_parameters});
}

sub body_parameters {
    my $self = shift;
    $self->env->{'plack.request.body'} ||= Hash::MultiValue->new(@{$self->_body_parameters});
}

# contains body + query
sub parameters {
    my $self = shift;

    $self->env->{'plack.request.merged'} ||= do {
        Hash::MultiValue->new(
            @{$self->_query_parameters},
            @{$self->_body_parameters}
        );
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

sub uri {
    my $self = shift;

    my $base = $self->_uri_base;

    # We have to escape back PATH_INFO in case they include stuff like
    # ? or # so that the URI parser won't be tricked. However we should
    # preserve '/' since encoding them into %2f doesn't make sense.
    # This means when a request like /foo%2fbar comes in, we recognize
    # it as /foo/bar which is not ideal, but that's how the PSGI PATH_INFO
    # spec goes and we can't do anything about it. See PSGI::FAQ for details.

    # See RFC 3986 before modifying.
    my $path_escape_class = q{^/;:@&=A-Za-z0-9\$_.+!*'(),-};

    my $path = URI::Escape::uri_escape($self->env->{PATH_INFO} || '', $path_escape_class);
    $path .= '?' . $self->env->{QUERY_STRING}
        if defined $self->env->{QUERY_STRING} && $self->env->{QUERY_STRING} ne '';

    $base =~ s!/$!! if $path =~ m!^/!;

    return URI->new($base . $path)->canonical;
}

sub base {
    my $self = shift;
    URI->new($self->_uri_base)->canonical;
}

sub _uri_base {
    my $self = shift;

    my $env = $self->env;

    my $uri = ($env->{'psgi.url_scheme'} || "http") .
        "://" .
        ($env->{HTTP_HOST} || (($env->{SERVER_NAME} || "") . ":" . ($env->{SERVER_PORT} || 80))) .
        ($env->{SCRIPT_NAME} || '/');

    return $uri;
}

sub new_response {
    my $self = shift;
    require Plack::Response;
    Plack::Response->new(@_);
}

sub request_body_parser {
    my $self = shift;
    $self->{request_body_parser} ||= $self->_build_body_parser;
}

sub _build_body_parser {
    my $self = shift;

    my $len = $self->_buffer_length_for($self->env);

    my $parser = HTTP::Entity::Parser->new(buffer_length => $len);
    $parser->register('application/x-www-form-urlencoded', 'HTTP::Entity::Parser::UrlEncoded');
    $parser->register('multipart/form-data', 'HTTP::Entity::Parser::MultiPart');

    $parser;
}

sub _buffer_length_for {
    my($self, $env) = @_;

    return $ENV{PLACK_BUFFER_LENGTH} if defined $ENV{PLACK_BUFFER_LENGTH};

    if ($env->{'psgix.input.buffered'}) {
        return 1024 * 1024; # 1MB for buffered
    } else {
        return 1024 * 64; # 64K for unbuffered
    }
}

sub _parse_request_body {
    my $self = shift;

    my ($params,$uploads) = $self->request_body_parser->parse($self->env);
    $self->env->{'plack.request.body_parameters'} = $params;

    my $upload_hash = Hash::MultiValue->new();
    while ( my ($k,$v) = splice @$uploads, 0, 2 ) {
        my %copy = %$v;
        $copy{headers} = HTTP::Headers::Fast->new(@{$v->{headers}});
        $upload_hash->add($k, Plack::Request::Upload->new(%copy));
    }
    $self->env->{'plack.request.upload'} = $upload_hash;
    1;
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
      my $query     = $req->parameters->{query};

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
PSGI (L<http://plackperl.org/#frameworks>), or see modules like
L<HTTP::Engine> to provide higher level Request and Response API on
top of PSGI.

If you're looking for an easy-to-use API to convert existing CGI
applications to run on PSGI, consider using L<CGI::PSGI> or
L<CGI::Emulate::PSGI> as well. L<CGI::Emulate::PSGI> documentation has
a good summary of using them to convert existing CGI scripts to adapt
to PSGI.

=head1 METHODS

Some of the methods defined in the earlier versions are deprecated in
version 0.99. Take a look at L</"INCOMPATIBILITIES">.

Unless otherwise noted, all methods and attributes are B<read-only>,
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
method and resolve on your own.

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

=item path

Similar to C<path_info> but returns C</> in case it is empty. In other
words, it returns the virtual path of the request URI after C<<
$req->base >>. See L</"DISPATCHING"> for details.

=item query_string

Returns B<QUERY_STRING> in the environment. This is the undecoded
query string in the request URI.

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

If there are multiple cookies with the same name in the request, this
method will ignore the duplicates and return only the first value. If
that causes issues for you, you may have to use modules like
CGI::Simple::Cookie to parse C<< $request->header('Cookie') >> by
yourself.

=item query_parameters

Returns a reference to a hash containing query string (GET)
parameters. This hash reference is L<Hash::MultiValue> object.

=item body_parameters

Returns a reference to a hash containing posted parameters in the
request body (POST). As with C<query_parameters>, the hash
reference is a L<Hash::MultiValue> object.

=item parameters

Returns a L<Hash::MultiValue> hash reference containing (merged) GET
and POST parameters.

=item content, raw_body

Returns the request content in an undecoded byte string for POST requests.

=item uri

Returns an URI object for the current request. The URI is constructed
using various environment values such as C<SCRIPT_NAME>, C<PATH_INFO>,
C<QUERY_STRING>, C<HTTP_HOST>, C<SERVER_NAME> and C<SERVER_PORT>.

Every time this method is called it returns a new, cloned URI object.

=item base

Returns an URI object for the base path of current request. This is
like C<uri> but only contains up to C<SCRIPT_NAME> where your
application is hosted at.

Every time this method is called it returns a new, cloned URI object.

=item user

Returns C<REMOTE_USER> if it's set.

=item headers

Returns an L<HTTP::Headers::Fast> object containing the headers for the current request.

=item uploads

Returns a reference to a hash containing uploads. The hash reference
is a L<Hash::MultiValue> object and values are L<Plack::Request::Upload>
objects.

=item content_encoding

Shortcut to $req->headers->content_encoding.

=item content_length

Returns the raw value of the Content-Length header.

Before version 0.9925, this method was a shortcut for
C<< $req->headers->content_length >>.

=item content_type

Returns the raw value of the Content-Type header.

If you want just the MIME type, without any attributes like charset, use
C<< $req->headers->content_type >>.  See also L<HTTP::Headers/content_type>.

Before version 0.9925, this method was a shortcut for
C<< $req->headers->content_type >>.

=item header

Shortcut to $req->headers->header.

=item referer

Shortcut to $req->headers->referer.

=item user_agent

Shortcut to $req->headers->user_agent.

=item param

Returns GET and POST parameters with a CGI.pm-compatible param
method. This is an alternative method for accessing parameters in
$req->parameters just in case you want the compatibility with
CGI.pm objects.

You are B<not recommended> to use this method since it is easy to
misuse in a list context such as inside a hash constructor or method
arguments. Use C<parameters> and Hash::MultiValue instead.

Unlike CGI.pm, it does I<not> allow setting or modifying query
parameters.

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

=head2 Hash::MultiValue parameters

Parameters that can take one or multiple values (i.e. C<parameters>,
C<query_parameters>, C<body_parameters> and C<uploads>) store the
hash reference as a L<Hash::MultiValue> object. This means you can use
the hash reference as a plain hash where values are B<always> scalars
(B<NOT> array references), so you don't need to code ugly and unsafe
C<< ref ... eq 'ARRAY' >> anymore.

And if you explicitly want to get multiple values of the same key, you
can call the C<get_all> method on it, such as:

  my @foo = $req->query_parameters->get_all('foo');

You can also call C<get_one> to always get one parameter independent
of the context (unlike C<param>), and even call C<mixed> (with
Hash::MultiValue 0.05 or later) to get the I<traditional> hash
reference,

  my $params = $req->parameters->mixed;

where values are either a scalar or an array reference depending on
input, so it might be useful if you already have the code to deal with
that ugliness.

=head2 PARSING POST BODY and MULTIPLE OBJECTS

The methods to parse request body (C<content>, C<body_parameters> and
C<uploads>) are carefully coded to save the parsed body in the
environment hash as well as in the temporary buffer, so you can call
them multiple times and create Plack::Request objects multiple times
in a request and they should work safely, and won't parse request body
more than twice for the efficiency.

=head1 DISPATCHING

If your application or framework wants to dispatch (or route) actions
based on request paths, be sure to use C<< $req->path_info >> not C<<
$req->uri->path >>.

This is because C<path_info> gives you the virtual path of the request,
regardless of how your application is mounted. If your application is
hosted with mod_perl or CGI scripts, or even multiplexed with tools
like L<Plack::App::URLMap>, request's C<path_info> always gives you
the action path.

Note that C<path_info> might give you an empty string, in which case
you should assume that the path is C</>.

You will also want to use C<< $req->base >> as a base prefix when
building URLs in your templates or in redirections. It's a good idea
for you to subclass Plack::Request and define methods such as:

  sub uri_for {
      my($self, $path, $args) = @_;
      my $uri = $self->base;
      $uri->path($uri->path . $path);
      $uri->query_form(@$args) if $args;
      $uri;
  }

So you can say:

  my $link = $req->uri_for('/logout', [ signoff => 1 ]);

and if C<< $req->base >> is C</app> you'll get the full URI for
C</app/logout?signoff=1>.

=head1 INCOMPATIBILITIES

In version 0.99, many utility methods are removed or deprecated, and
most methods are made read-only. These methods were deleted in version
1.0001.

All parameter-related methods such as C<parameters>,
C<body_parameters>, C<query_parameters> and C<uploads> now contains
L<Hash::MultiValue> objects, rather than I<scalar or an array
reference depending on the user input> which is insecure. See
L<Hash::MultiValue> for more about this change.

C<< $req->path >> method had a bug, where the code and the document
was mismatching. The document was suggesting it returns the sub
request path after C<< $req->base >> but the code was always returning
the absolute URI path. The code is now updated to be an alias of C<<
$req->path_info >> but returns C</> in case it's empty. If you need
the older behavior, just call C<< $req->uri->path >> instead.

Cookie handling is simplified, and doesn't use L<CGI::Simple::Cookie>
anymore, which means you B<CAN NOT> set array reference or hash
reference as a cookie value and expect it be serialized. You're always
required to set string value, and encoding or decoding them is totally
up to your application or framework. Also, C<cookies> hash reference
now returns I<strings> for the cookies rather than CGI::Simple::Cookie
objects, which means you no longer have to write a wacky code such as:

  $v = $req->cookies->{foo} ? $req->cookies->{foo}->value : undef;

and instead, simply do:

  $v = $req->cookies->{foo};

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
