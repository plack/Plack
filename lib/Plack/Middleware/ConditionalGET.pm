package Plack::Middleware::ConditionalGET;
use strict;
use base qw( Plack::Middleware );
use Plack::Util;

sub call {
    my $self = shift;
    my $env  = shift;

    my $res = $self->app->($env);
    return $res unless $env->{REQUEST_METHOD} =~ /^(GET|HEAD)$/;

    if ( $self->etag_matches($res->[1], $env) || $self->not_modified_since($res->[1], $env) ) {
        $res->[0] = 304;
        Plack::Util::header_remove($res->[1], $_)
            for qw( Content-Type Content-Length Content-Disposition );
        $res->[2] = [];
    }

    return $res;
}

no warnings 'uninitialized';

sub etag_matches {
    my($self, $headers, $env) = @_;
    my $val = Plack::Util::header_get($headers, 'ETag');
    defined $val && $val eq $env->{HTTP_IF_NONE_MATCH};
}

sub not_modified_since {
    my($self, $headers, $env) = @_;
    my $val = Plack::Util::header_get($headers, 'Last-Modified');
    defined $val && $val eq $env->{HTTP_IF_MODIFIED_SINCE};
}

1;

__END__

=head1 NAME

Plack::Middleware::ConditionalGET - Middleware to enable conditional GET

=head1 SYNOPSIS

  builder {
      enable Plack::Middleware::ConditionalGET;
      ....
  };

=head1 DESCRIPTION

This middleware enables conditional GET and HEAD using
C<If-None-Match> and C<If-Modified-Since> header. The application
should set either or both of C<Last-Modified> or C<ETag> response
headers per RFC 2616. When either of the conditions is met, the
response body is set to be zero length and the status is set to 304
Not Modified.

=head1 SEE ALSO

Rack::ConditionalGet

=cut
