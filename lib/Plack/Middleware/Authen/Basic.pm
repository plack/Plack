package Plack::Middleware::Authen::Basic;
use strict;
use parent qw(Plack::Middleware);
__PACKAGE__->mk_accessors(qw(realm authenticator));

use MIME::Base64;

sub call {
    my($self, $env) = @_;

    my $auth = $env->{HTTP_AUTHORIZATION}
        or return $self->unauthorized;

    if ($auth =~ /^Basic (.*)$/) {
        my($user, $pass) = split /:/, (MIME::Base64::decode($1) || ":");
        my $auth = $self->authenticator or die 'authenticator is not set';
        if ($auth->($user, $pass)) {
            $env->{REMOTE_USER} = $user;
            return $self->app->($env);
        }
    }

    return $self->unauthorized;
}

sub unauthorized {
    my $self = shift;
    my $body = 'Authorization required';
    return [
        401,
        [ 'Content-Type' => 'text/plain',
          'Content-Length' => length $body,
          'WWW-Authenticate' => 'Basic realm="' . ($self->realm || "restricted area") . '"' ],
        [ $body ],
    ];
}

1;

__END__

=head1 NAME

Plack::Middleware::Authen::Basic - Simple basic authentication middleware

=head1 SYNOPSIS

  use Plack::Builder;
  my $app = sub { ... };

  builder {
      enable "Authen::Basic", authenticator => \&authen_cb;
      $app;
  };

  sub authen_cb {
      my($username, $password) = @_;
      return $username eq 'admin' && $password eq 's3cr3t';
  }

=head1 DESCRIPTION

Plack::Middleware::Authen::Basic is a basic authentication handler for Plack.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plack>

=cut
