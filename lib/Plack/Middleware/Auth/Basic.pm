package Plack::Middleware::Auth::Basic;
use strict;
use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw( realm authenticator );
use Scalar::Util;
use MIME::Base64;

sub prepare_app {
    my $self = shift;

    my $auth = $self->authenticator or die 'authenticator is not set';
    if (Scalar::Util::blessed($auth) && $auth->can('authenticate')) {
        $self->authenticator(sub { $auth->authenticate(@_[0,1]) }); # because Authen::Simple barfs on 3 params
    } elsif (ref $auth ne 'CODE') {
        die 'authenticator should be a code reference or an object that responds to authenticate()';
    }
}

sub call {
    my($self, $env) = @_;

    my $auth = $env->{HTTP_AUTHORIZATION}
        or return $self->unauthorized;

    # note the 'i' on the regex, as, according to RFC2617 this is a 
    # "case-insensitive token to identify the authentication scheme"
    if ($auth =~ /^Basic (.*)$/i) {
        my($user, $pass) = split /:/, (MIME::Base64::decode($1) || ":"), 2;
        $pass = '' unless defined $pass;
        if ($self->authenticator->($user, $pass, $env)) {
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

Plack::Middleware::Auth::Basic - Simple basic authentication middleware

=head1 SYNOPSIS

  use Plack::Builder;
  my $app = sub { ... };

  builder {
      enable "Auth::Basic", authenticator => \&authen_cb;
      $app;
  };

  sub authen_cb {
      my($username, $password, $env) = @_;
      return $username eq 'admin' && $password eq 's3cr3t';
  }

=head1 DESCRIPTION

Plack::Middleware::Auth::Basic is a basic authentication handler for Plack.

=head1 CONFIGURATION

=over 4

=item authenticator

A callback function that takes username, password and PSGI environment
supplied and returns whether the authentication succeeds. Required.

Authenticator can also be an object that responds to C<authenticate>
method that takes username and password and returns boolean, so
backends for L<Authen::Simple> is perfect to use:

  use Authen::Simple::LDAP;
  enable "Auth::Basic", authenticator => Authen::Simple::LDAP->new(...);

=item realm

Realm name to display in the basic authentication dialog. Defaults to I<restricted area>.

=back

=head1 LIMITATIONS

This middleware expects that the application has a full access to the
headers sent by clients in PSGI environment. That is normally the case
with standalone Perl PSGI web servers such as L<Starman> or
L<HTTP::Server::Simple::PSGI>.

However, in a web server configuration where you can't achieve this
(i.e. using your application via Apache's mod_cgi), this middleware
does not work since your application can't know the value of
C<Authorization:> header.

If you use Apache as a web server and CGI to run your PSGI
application, you can either a) compile Apache with
C<-DSECURITY_HOLE_PASS_AUTHORIZATION> option, or b) use mod_rewrite to
pass the Authorization header to the application with the rewrite rule
like following.

  RewriteEngine on
  RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization},L]

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plack>

=cut
