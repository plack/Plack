package Plack::Response;
use strict;
use warnings;
our $VERSION = '1.0051';

use Plack::Util::Accessor qw(body status);
use Carp ();
use Cookie::Baker ();
use Scalar::Util ();
use HTTP::Headers::Fast;
use URI::Escape ();

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
            $headers = HTTP::Headers::Fast->new(@$headers);
        } elsif (ref $headers eq 'HASH') {
            $headers = HTTP::Headers::Fast->new(%$headers);
        }
        return $self->{headers} = $headers;
    } else {
        return $self->{headers} ||= HTTP::Headers::Fast->new();
    }
}

sub cookies {
    my $self = shift;
    if (@_) {
        $self->{cookies} = shift;
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
    my $self = shift;
    return $self->headers->header('Location' => @_);
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
    Carp::croak "missing status" unless $self->status();

    my $headers = $self->headers;
    my @headers;
    $headers->scan(sub{
        my ($k,$v) = @_;
        $v =~ s/\015\012[\040|\011]+/chr(32)/ge; # replace LWS with a single SP
        $v =~ s/\015|\012//g; # remove CR and LF since the char is invalid here
        push @headers, $k, $v;
    });

    $self->_finalize_cookies(\@headers);

    return [
        $self->status,
        \@headers,
        $self->_body,
    ];
}

sub to_app {
    my $self = shift;
    return sub { $self->finalize };
}


sub _body {
    my $self = shift;
    my $body = $self->body;
       $body = [] unless defined $body;
    if (!ref $body or Scalar::Util::blessed($body) && overload::Method($body, q("")) && !$body->can('getline')) {
        return [ $body ];
    } else {
        return $body;
    }
}

sub _finalize_cookies {
    my($self, $headers) = @_;

    foreach my $name ( keys %{ $self->cookies } ) {
        my $val = $self->cookies->{$name};

        my $cookie = Cookie::Baker::bake_cookie( $name, $val );
        push @$headers, 'Set-Cookie' => $cookie;
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
  $res->headers( HTTP::Headers::Fast->new );

Sets and gets HTTP headers of the response. Setter can take either an
array ref, a hash ref or L<HTTP::Headers::Fast> object containing a list of
headers.

=item body

  $res->body($body_str);
  $res->body([ "Hello", "World" ]);
  $res->body($io);

Gets and sets HTTP response body. Setter can take either a string, an
array ref, or an IO::Handle-like object. C<content> is an alias.

Note that this method doesn't automatically set I<Content-Length> for
the response. You have to set it manually if you want, with the
C<content_length> method (see below).

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

Note that this method doesn't normalize the given URI string. Users of
this module have to be responsible about properly encoding URI paths
and parameters.

=item location

Gets and sets C<Location> header.

Note that this method doesn't normalize the given URI string in the
setter. See above in C<redirect> for details.

=item cookies

  $res->cookies->{foo} = 123;
  $res->cookies->{foo} = { value => '123' };

Returns a hash reference containing cookies to be set in the
response. The keys of the hash are the cookies' names, and their
corresponding values are a plain string (for C<value> with everything
else defaults) or a hash reference that can contain keys such as
C<value>, C<domain>, C<expires>, C<path>, C<httponly>, C<secure>,
C<max-age>.

C<expires> can take a string or an integer (as an epoch time) and
B<does not> convert string formats such as C<+3M>.

  $res->cookies->{foo} = {
      value => 'test',
      path  => "/",
      domain => '.example.com',
      expires => time + 24 * 60 * 60,
  };

=item finalize

  $res->finalize;

Returns the status code, headers, and body of this response as a PSGI
response array reference.

=item to_app

  $app = $res->to_app;

A helper shortcut for C<< sub { $res->finalize } >>.


=back

=head1 AUTHOR

Tokuhiro Matsuno

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plack::Request>

=cut
