package Plack::Middleware::Conditional;
use strict;
use parent qw(Plack::Middleware);

use Plack::Util::Accessor qw( condition middleware builder );

sub prepare_app {
    my $self = shift;
    $self->middleware( $self->builder->($self->app) );
}

sub call {
    my($self, $env) = @_;

    my $app = $self->condition->($env) ? $self->middleware : $self->app;
    return $app->($env);
}

1;

__END__

=head1 NAME

Plack::Middleware::Conditional - Conditional wrapper for Plack middleware

=head1 SYNOPSIS

  use Plack::Builder;

  builder {
      enable_if { $_[0]->{REMOTE_ADDR} eq '127.0.0.1' } 'StackTrace', force => 1;
      $app;
  };

  # or using the OO interface:
  $app = Plack::Middleware::Conditional->wrap(
      $app,
      condition  => sub { $_[0]->{REMOTE_ADDR} eq '127.0.0.1' },
      builder => sub { Plack::Middleware::StackTrace->wrap($_[0], force => 1) },
  );

=head1 DESCRIPTION

Plack::Middleware::Conditional is a piece of meta-middleware, to run a
specific middleware component under runtime conditions. The goal of
this middleware is to avoid baking runtime configuration options in
individual middleware components, and rather share them as another
middleware component.

=head1 EXAMPLES

Note that some of the middleware component names are just made up for
the explanation and might not exist.

  # Minify JavaScript if the browser is Firefox
  enable_if { $_[0]->{HTTP_USER_AGENT} =~ /Firefox/ } 'JavaScriptMinifier';

  # Enable Stacktrace when being accessed from the local network
  enable_if { $_[0]->{REMOTE_ADDR} =~ /^10\.0\.1\.*/ } 'StackTrace';

  # Work with other conditional setter middleware:
  # Transcode Jpeg on the fly for mobile clients
  builder {
      enable 'MobileDetector';
      enable_if { $_[0]->{'plack.mobile_detected'} }
        'TranscodeJpeg', max_size => 30_000;
      $app;
  };

Note that in the last example I<MobileDetector> should come first
because the conditional check runs in I<pre-run> conditions, which is
from outer to inner: that is, from the top to the bottom in the
Builder DSL code.

=head1 AUTHOR

Tatsuhiko Miyagawa

Steve Cook

=head1 SEE ALSO

L<Plack::Builder>

=cut
