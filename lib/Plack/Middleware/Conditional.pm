package Plack::Middleware::Conditional;
use strict;
use parent qw(Plack::Middleware);

use Plack::Util::Accessor qw( condition middleware builder );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->middleware( $self->builder->($self->app) );
    $self;
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
      enable_if { $_[0]->{REMOTE_ADDR} eq '127.0.0.1' } 'StackTrace';
      $app;
  };

  # Or more raw version of it
  $app = Plack::Middleware::Conditional->wrap(
      $app,
      condition  => sub { my $env = shift; $env->{HTTP_USER_AGENT} =~ /WebKit/ },
      builder => sub { Plack::Middleware::SuperAdminConsole->wrap($_[0], @args) },
  );

=head1 DESCRIPTION

Plack::Middleware::Conditional is a piece of meta-middleware, to run a
specific middleware component under the runtime condition. The goal of
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
because the conditional check runs in I<pre-run> condition, which is
from outer to inner and that is from the top to the bottom in the
Builder DSL code.

=head1 AUTHOR

Tatsuhiko Miyagawa

Steve Cook

=head1 SEE ALSO

L<Plack::Builder>

=cut
