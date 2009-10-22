package Plack::Middleware::RearrangeHeaders;
use strict;
use warnings;
use parent qw( Plack::Middleware );

use HTTP::Headers;

sub call {
    my $self = shift;

    my $res = $self->app->(@_);
    $self->response_cb($res, sub {
        my $res = shift;

        my $h = HTTP::Headers->new(@{$res->[1]});
        my @new_headers;
        $h->scan(sub { push @new_headers, @_ });

        $res->[1] = \@new_headers;
    });
}

1;

__END__

=head1 NAME

Plack::Middleware::RearrangeHeaders - Reorder HTTP headers for buggy clients

=head1 SYNOPSIS

  use Plack::Builder;

  my $app = sub {
      return [ 200, [
          'Last-Modified' => 'Wed, 23 Sep 2009 13:36:33 GMT',
          'Content-Type' => 'text/plain',
          'ETag' => 'foo bar',
      ], [ 'Hello Foo' ] ];
  };

  builder {
      enable "Plack::Middleware::RearrangeHeaders";
      $app;
  };

=head1 DESCRIPTION

Plack::Middleware::RearrangeHeaders sorts HTTP headers based on "Good Practice" i.e.:

  # "Good Practice" order of HTTP message headers:
  #    - Response-Headers
  #    - Entity-Headers

to work around buggy clients like very old MSIE or broken HTTP proxy
servers. Most clients today don't (and shouldn't) care about HTTP
header order but if you're too pedantic or have some environments
where you need to deal with buggy clients like above, this might be
useful.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<HTTP::Headers>

=cut
