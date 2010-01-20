package Plack::Response;
use strict;
use warnings;
our $VERSION = '0.01';
use base qw/Class::Accessor::Fast/;
use Carp ();
use Scalar::Util ();
use CGI::Simple::Cookie ();
use HTTP::Headers;

__PACKAGE__->mk_accessors(qw/body status/);
sub code    { shift->status(@_) }
sub content { shift->body(@_)   }

sub new {
    my($class, $rc, $headers, $content) = @_;

    my $self = bless {}, $class;
    $self->status($rc)       if defined $rc;
    $self->headers($headers) if defined $headers;
    $self->body($content)    if defined $content;

    $self;
}

sub headers {
    my $self = shift;

    if (@_) {
        my $headers = shift;
        if (ref $headers eq 'ARRAY') {
            Carp::carp("Odd number of headers") if @$headers % 2 != 0;
            $headers = HTTP::Headers->new(@$headers);
        } elsif (ref $headers eq 'HASH') {
            $headers = HTTP::Headers->new(%$headers);
        }
        return $self->{headers} = $headers;
    } else {
        return $self->{headers} ||= HTTP::Headers->new();
    }
}

sub cookies {
    my $self = shift;
    if (@_) {
        return $self->{cookies} = shift;
    } else {
        return $self->{cookies} ||= +{ };
    }
}

sub header { shift->headers->header(@_) } # shortcut

sub content_length {
    shift->headers->content_length(@_);
}

sub content_type {
    shift->headers->content_type(@_);
}

sub content_encoding {
    shift->headers->content_encoding(@_);
}

sub location {
    shift->headers->header('Location' => @_);
}

sub redirect {
    my $self = shift;

    if (@_) {
        my $url = shift;
        my $status = shift || 302;
        $self->location($url);
        $self->status($status);
    }

    return $self->location;
}

sub finalize {
    my $self = shift;
    die "missing status" unless $self->status();

    $self->_finalize_cookies();

    return [
        $self->status,
        +[
            map {
                my $k = $_;
                map { ( $k => $_ ) } $self->headers->header($_);
            } $self->headers->header_field_names
        ],
        $self->_body,
    ];
}

sub _body {
    my $self = shift;
    my $body = $self->body;
       $body = [] unless defined $body;
    if (!ref $body or Scalar::Util::blessed($body) && overload::Method($body, q(""))) {
        return [ $body ];
    } else {
        return $body;
    }
}

sub _finalize_cookies {
    my ( $self ) = @_;

    my $cookies = $self->cookies;
    my @keys    = keys %$cookies;
    if (@keys) {
        for my $name (@keys) {
            my $val    = $cookies->{$name};
            my $cookie = (
                Scalar::Util::blessed($val)
                ? $val
                : CGI::Simple::Cookie->new(
                    -name    => $name,
                    -value   => $val->{value},
                    -expires => $val->{expires},
                    -domain  => $val->{domain},
                    -path    => $val->{path},
                    -secure  => ( $val->{secure} || 0 )
                )
            );

            $self->headers->push_header( 'Set-Cookie' => $cookie->as_string );
        }
    }
}

1;
__END__

=head1 NAME

Plack::Response - Portable HTTP Response object for PSGI response

=head1 SYNOPSIS

  use Plack::Response;

  sub psgi_handler {
      my $env = shift;

      my $res = Plack::Response->new(200);
      $res->content_type('text/html');
      $res->body("Hello World");

      return $res->finalize;
  }

=head1 DESCRIPTION

Plack::Response allows you a way to create PSGI response array ref through a simple API.

=head1 METHODS

=over 4

=item new

  $res = Plack::Response->new;
  $res = Plack::Response->new($status);
  $res = Plack::Response->new($status, $headers);
  $res = Plack::Response->new($status, $headers, $body);

Creates a new Plack::Response object.

=item status

  $res->status(200);
  $status = $res->status;

Sets and gets HTTP status code. C<code> is an alias.

=item headers

  $headers = $res->headers;
  $res->headers([ 'Content-Type' => 'text/html' ]);
  $res->headers({ 'Content-Type' => 'text/html' });
  $res->headers( HTTP::Headers->new );

Sets and gets HTTP headers of the response. Setter can take either an
array ref, a hash ref or L<HTTP::Headers> object containing a list of
headers.

=item body

  $res->body($body_str);
  $res->body([ "Hello", "World" ]);
  $res->body($io);

Gets and sets HTTP response body. Setter can take either a string, an
array ref, or an IO::Handle-like object. C<content> is an alias.

=item header

  $res->header('X-Foo' => 'bar');
  my $val = $res->header('X-Foo');

Shortcut for C<< $res->headers->header >>.

=item content_type, content_length, content_encoding

  $res->content_type('text/plain');
  $res->content_length(123);
  $res->content_encoding('gzip');

Shortcut for the equivalent get/set methods in C<< $res->headers >>.

=item redirect

  $res->redirect($url);
  $res->redirect($url, 301);

Sets redirect URL with an optional status code, which defaults to 302.

=item location

Gets and sets C<Location> header.

=item cookies

  $res->cookies->{foo} = { value => '123' };

Returns a hash reference containing cookies to be set in the
response. The keys of the hash are the cookies' names, and their
corresponding values are hash reference used to construct a
CGI::Simple::Cookie object.

=back

=head1 AUTHOR

Tokuhiro Matsuno

=head1 SEE ALSO

L<Plack::Request>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
