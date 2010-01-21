package Plack::Request;
use strict;
use warnings;
use 5.008_001;
our $VERSION = "0.09";

use HTTP::Headers;
use URI::QueryParam;
use Carp ();

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

    bless {
        env => $env,
    }, $class;
}

sub env { $_[0]->{env} }

sub address     { $_[0]->env->{REMOTE_ADDR} }
sub remote_host { $_[0]->env->{REMOTE_HOST} }
sub protocol    { $_[0]->env->{SERVER_PROTOCOL} }
sub method      { $_[0]->env->{REQUEST_METHOD} }
sub port        { $_[0]->env->{SERVER_PORT} }
sub user        { $_[0]->env->{REMOTE_USER} }
sub request_uri { $_[0]->env->{REQUEST_URI} }
sub url_scheme  { $_[0]->env->{'psgi.url_scheme'} }
sub session     { $_[0]->env->{'psgix.session'} }

sub hostname {
    my $self = shift;
    _deprecated;
    $self->remote_host || $self->address;
}

sub secure {
    $_[0]->url_scheme eq 'https';
}

# we need better cookie lib?
# http://mark.stosberg.com/blog/2008/12/cookie-handling-in-titanium-catalyst-and-mojo.html
sub cookies {
    my $self = shift;
    if (defined $_[0]) {
        unless (ref($_[0]) eq 'HASH') {
            Carp::croak "Attribute (cookies) does not pass the type constraint because: Validation failed for 'HashRef' failed with value $_[0]";
        }
        $self->{cookies} = $_[0];
    } elsif (!defined $self->{cookies}) {
        require CGI::Simple::Cookie;
        if (my $header = $self->header('Cookie')) {
            $self->{cookies} = { CGI::Simple::Cookie->parse($header) };
        } else {
            $self->{cookies} = {};
        }
    }
    $self->{cookies};
}

sub query_parameters {
    my $self = shift;
    if (defined $_[0]) {
        unless (ref($_[0]) eq 'HASH') {
            Carp::croak "Attribute (query_parameters) does not pass the type constraint because: Validation failed for 'HashRef' failed with value $_[0]";
        }
        $self->{query_parameters} = $_[0];
    } elsif (!defined $self->{query_parameters}) {
        $self->{query_parameters} = $self->uri->query_form_hash;
    }
    $self->{query_parameters};
}

sub _body_parser {
    my $self = shift;
    unless (defined $self->{_body_parser}) {
        require Plack::Request::BodyParser;
        $self->{_body_parser} = Plack::Request::BodyParser->new( $self->env );
    }
    $self->{_body_parser};
}

sub raw_body {
    my $self = shift;
    if (!defined($self->{raw_body})) {
        $self->{raw_body} ||= $self->_body_parser->raw_body($self);
    }
    $self->{raw_body};
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

# TODO: This attribute should be private. I will remove deps for HTTP::Body
sub _http_body {
    my $self = shift;
    if (!defined $self->{_http_body}) {
        $self->{_http_body} = $self->_body_parser->http_body();
    }
    $self->{_http_body};
}
sub body_parameters {
    my $self = shift;

    if (@_ || defined $self->{_http_body} || $self->method eq 'POST') {
        return $self->_http_body->param(@_);
    } else {
        return {};
    }
}

sub body            { shift->_http_body->body(@_) }

# contains body_params and query_params
sub parameters {
    my $self = shift;
    if (defined $_[0]) {
        unless (ref($_[0]) eq 'HASH') {
            Carp::croak "Attribute (parameters) does not pass the type constraint because: Validation failed for 'HashRef' failed with value $_[0]";
        }
        $self->{parameters} = $_[0];
    } elsif (!defined $self->{parameters}) {
        $self->{parameters} = $self->_build_parameters;
    }
    $self->{parameters};
}
sub _build_parameters {
    my $self = shift;

    my $query = $self->query_parameters;
    my $body  = $self->body_parameters;

    my %merged;

    foreach my $hash ( $query, $body ) {
        foreach my $name ( keys %$hash ) {
            my $param = $hash->{$name};
            push( @{ $merged{$name} ||= [] }, ( ref $param ? @$param : $param ) );
        }
    }

    foreach my $param ( values %merged ) {
        $param = $param->[0] if @$param == 1;
    }

    return \%merged;
}

sub uploads {
    my $self = shift;
    if (defined $_[0]) {
        unless (ref($_[0]) eq 'HASH') {
            Carp::croak "Attribute (uploads) does not pass the type constraint because: Validation failed for 'HashRef' failed with value $_[0]";
        }
        $self->{uploads} = $_[0];
    } elsif (!defined $self->{uploads}) {
        $self->{uploads} = $self->_build_uploads;
    }
    $self->{uploads};
}
sub _build_uploads {
    my $self = shift;
    my $uploads = $self->_http_body->upload;
    my %uploads;
    for my $name (keys %{ $uploads }) {
        my $files = $uploads->{$name};
        $files = ref $files eq 'ARRAY' ? $files : [$files];

        my @uploads;
        for my $upload (@{ $files }) {
            my $headers = HTTP::Headers->new( %{ $upload->{headers} } );
            push(
                @uploads,
                Plack::Request::Upload->new(
                    headers  => $headers,
                    tempname => $upload->{tempname},
                    size     => $upload->{size},
                    filename => $upload->{filename},
                )
            );
        }
        $uploads{$name} = @uploads > 1 ? \@uploads : $uploads[0];

        # support access to the filename as a normal param
        my @filenames = map { $_->{filename} } @uploads;
        $self->parameters->{$name} =  @filenames > 1 ? \@filenames : $filenames[0];
    }
    return \%uploads;
}

# aliases
sub body_params  { shift->body_parameters(@_) }
sub input        { shift->body(@_) }
sub params       { shift->parameters(@_) }
sub query_params { shift->query_parameters(@_) }

sub path_info    { shift->env->{PATH_INFO} }
sub script_name  { shift->env->{SCRIPT_NAME} }

sub cookie {
    my $self = shift;

    return keys %{ $self->cookies } if @_ == 0;

    if (@_ == 1) {
        my $name = shift;
        return undef unless exists $self->cookies->{$name}; ## no critic.
        return $self->cookies->{$name};
    }
    return;
}

sub param {
    my $self = shift;

    return keys %{ $self->parameters } if @_ == 0;

    if (@_ == 1) {
        my $param = shift;
        return wantarray ? () : undef unless exists $self->parameters->{$param};

        if ( ref $self->parameters->{$param} eq 'ARRAY' ) {
            return (wantarray)
              ? @{ $self->parameters->{$param} }
                  : $self->parameters->{$param}->[0];
        } else {
            return (wantarray)
              ? ( $self->parameters->{$param} )
                  : $self->parameters->{$param};
        }
    } else {
        my $field = shift;
        $self->parameters->{$field} = [@_];
    }
}

sub upload {
    my $self = shift;

    return keys %{ $self->uploads } if @_ == 0;

    if (@_ == 1) {
        my $upload = shift;
        return wantarray ? () : undef unless exists $self->uploads->{$upload};

        if (ref $self->uploads->{$upload} eq 'ARRAY') {
            return (wantarray)
              ? @{ $self->uploads->{$upload} }
          : $self->uploads->{$upload}->[0];
        } else {
            return (wantarray)
              ? ( $self->uploads->{$upload} )
          : $self->uploads->{$upload};
        }
    } else {
        while ( my($field, $upload) = splice(@_, 0, 2) ) {
            if ( exists $self->uploads->{$field} ) {
                for ( $self->uploads->{$field} ) {
                    $_ = [$_] unless ref($_) eq "ARRAY";
                    push(@{ $_ }, $upload);
                }
            } else {
                $self->uploads->{$field} = $upload;
            }
        }
    }
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
    if (defined $_[0]) {
        unless (eval { $_[0]->isa('URI') }) {
            Carp::croak "Attribute (uri) does not pass the type constraint because: Validation failed for 'URI' failed with value $_[0]";
        }
        $self->{uri} = $_[0];
    } elsif (!defined $self->{uri}) {
        $self->{uri} = $self->_build_uri;
    }
    $self->{uri};
}

sub _build_uri  {
    my($self, ) = @_;

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

sub path { shift->uri->path(@_) }

sub new_response {
    my $self = shift;
    require Plack::Response;
    Plack::Response->new(@_);
}

sub content {
    my ( $self, @args ) = @_;

    if ( @args ) {
        Carp::croak "The HTTP::Request method 'content' is unsupported when used as a writer, use Plack::RequestBuilder";
    } else {
        return $self->raw_body;
    }
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

Returns the request uri (like $ENV{REQUEST_URI})

=item query_parameters

Returns a reference to a hash containing query string (GET)
parameters. Values can be either a scalar or an arrayref containing
scalars.

=item secure

Returns true or false, indicating whether the connection is secure (https).

=item uri

Returns a URI object for the current request. Stringifies to the URI text.

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

Like L<CGI>, and B<unlike> earlier versions of Catalyst, passing multiple
arguments to this method, like this:

    $req->param( 'foo', 'bar', 'gorch', 'quxx' );

will set the parameter C<foo> to the multiple values C<bar>, C<gorch> and
C<quxx>. Previously this would have added C<bar> as another value to C<foo>
(creating it if it didn't exist before), and C<quxx> as another value for
C<gorch>.

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

Creates a new L<Plack::Response> by default. Handy to remove
dependency on L<Plack::Response> in your code for easy subclassing and
duck typing in web application frameworks, as well as overriding
Response generation in middlewares.

=back

=head1 AUTHORS

Kazuhiro Osawa

Tokuhiro Matsuno

=head1 SEE ALSO

L<Plack::Response> L<HTTP::Request>, L<Catalyst::Request>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
