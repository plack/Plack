package Plack::Middleware::MethodOverride;
use strict;
use warnings;
use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw( header );

my %allowed_method = map { $_ => 1 } qw( GET HEAD POST PUT DELETE );

sub call {
    my $self = shift;
    my $env  = shift;

    my $key = $self->header || 'X-HTTP-Method-Override';
       $key =~ tr/-/_/;

    my $method = $env->{"HTTP_" . uc($key)};
    if (defined $method && $allowed_method{$method}) {
        $env->{REQUEST_METHOD} = $method;
    }

    $self->app->($env);
}

1;

__END__

=head1 NAME

Plack::Middleware::MethodOverride - Overrides HTTP method with X-HTTP-Method-Override header

=head1 SYNOPSIS

  use Plack::Builder;

  builder {
      enable "Plack::Middleware::MethodOverride";
      $handler;
  };

=head1 DESCRIPTION

Plack::Middleware::MethodOverride allows your application to override
HTTP request method with the value specified in HTTP header value.

=head1 CONFIGURATIONS

=over 4

=item header

   enable "Plack::Middleware::MethodOverride",
       header => 'X-HTTP-Method';

Specifies the HTTP header name to specify the overriding HTTP
method. Defaults to C<X-HTTP-Method-Override>.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

Based on L<HTTP::Engine::Middleware::MethodOverride>

=head1 SEE ALSO

L<Plack::Middleware>

=cut
