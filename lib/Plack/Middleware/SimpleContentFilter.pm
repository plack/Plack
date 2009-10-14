package Plack::Middleware::SimpleContentFilter;
use strict;
use warnings;
use parent qw( Plack::Middleware );
__PACKAGE__->mk_accessors(qw(filter));

use Plack::Util;

sub call {
    my $self = shift;

    my($status, $header, $body) = @{$self->app->(@_)};

    my $h = Plack::Util::headers($header);

    unless ($h->get('Content-Type') =~ m!^text/!) {
        return [ $status, $header, $body ]
    }

    my $getline = ref $body eq 'ARRAY' ? sub { shift @$body } : sub { $body->getline };

    my $body_filter = Plack::Util::inline_object(
        getline => sub {
            my $line = $getline->();
            return unless defined $line;
            local $_ = $line;
            $self->filter->();
            return $_;
        },
        close => sub {
            $body->close unless ref $body eq 'ARRAY';
        },
    );

    return [ $status, $header, $body_filter ];
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
