package Plack::Middleware::ConditionalGET;
use strict;
use base qw( Plack::Middleware );
use Plack::Util;

sub call {
    my $self = shift;
    my $env  = shift;

    my $res = $self->app->($env, @_);
    return $res unless $env->{REQUEST_METHOD} =~ /^(GET|HEAD)$/;

    # TODO this should really be in Plack::Util
    my %headers;
    while (my($key, $value) = splice @{$res->[1]}, 0, 2) {
        push @{$headers{$key}}, $value;
    }

    if ( $self->etag_matches(\%headers, $env) || $self->not_modified_since(\%headers, $env) ) {
        $res->[0] = 304;
        delete $headers{'Content-Type'};
        delete $headers{'Content-Length'};

        my @headers;
        while (my($key, $val_r) = each %headers) {
            push @headers, $key, $_ for @$val_r;
        }
        $res->[1] = \@headers;
        $res->[2] = [];
    }

    return $res;
}

no warnings 'uninitialized';

sub etag_matches {
    my($self, $headers, $env) = @_;
    $headers->{ETag} && $headers->{ETag}[0] eq $env->{HTTP_IF_NONE_MATCH};
}

sub not_modified_since {
    my($self, $headers, $env) = @_;
    $headers->{'Last-Modified'} && $headers->{'Last-Modified'}[0] eq $env->{HTTP_IF_MODIFIED_SINCE};
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
