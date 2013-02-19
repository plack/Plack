package Plack::Middleware::SimpleContentFilter;
use strict;
use warnings;
use parent qw( Plack::Middleware );

use Plack::Util;
use Plack::Util::Accessor qw( filter );

sub call {
    my $self = shift;

    my $res = $self->app->(@_);
    $self->response_cb($res, sub {
        my $res = shift;
        my $h = Plack::Util::headers($res->[1]);
        return unless $h->get('Content-Type');
        if ($h->get('Content-Type') =~ m!^text/!) {
            return sub {
                my $chunk = shift;
                return unless defined $chunk;
                local $_ = $chunk;
                $self->filter->();
                return $_;
            };
        }
    });
}

1;

__END__

=head1 NAME

Plack::Middleware::SimpleContentFilter - Filters response content

=head1 SYNOPSIS

  use Plack::Builder;

  my $app = sub {
      return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello Foo' ] ];
  };

  builder {
      enable "Plack::Middleware::SimpleContentFilter",
          filter => sub { s/Foo/Bar/g; };
      $app;
  };

=head1 DESCRIPTION

B<This middleware should be considered as a demo. Running this against
your application might break your HTML unless you code the filter
callback carefully>.

Plack::Middleware::SimpleContentFilter is a simple content text filter
to run against response body. This middleware is only enabled against
responses with C<text/*> Content-Type.

=head1 AUTHOR

Tatsuhiko Miyagawa

=cut
