package Plack::Middleware::ConditionalGET;
use strict;
use parent qw( Plack::Middleware );
use Plack::Util;

sub call {
    my $self = shift;
    my $env  = shift;

    my $res = $self->app->($env);
    return $res unless $env->{REQUEST_METHOD} =~ /^(GET|HEAD)$/;

    $self->response_cb($res, sub {
        my $res = shift;

        my $h = Plack::Util::headers($res->[1]);
        if ( $self->etag_matches($h, $env) || $self->not_modified_since($h, $env) ) {
            $res->[0] = 304;
            $h->remove($_) for qw( Content-Type Content-Length Content-Disposition );
            if ($res->[2]) {
                $res->[2] = [];
            } else {
                return sub {
                    return defined $_[0] ? '' : undef;
                };
            }
        }
    });
}

no warnings 'uninitialized';

# RFC 2616 14.25 says it's OK and expected to use 'eq' :)
# > Note: When handling an If-Modified-Since header field, some
# > servers will use an exact date comparison function, rather than a
# > less-than function, for deciding whether to send a 304 ...

sub etag_matches {
    my($self, $h, $env) = @_;
    $h->exists('ETag') && $h->get('ETag') eq _value($env->{HTTP_IF_NONE_MATCH});
}

sub not_modified_since {
    my($self, $h, $env) = @_;
    $h->exists('Last-Modified') && $h->get('Last-Modified') eq _value($env->{HTTP_IF_MODIFIED_SINCE});
}

sub _value {
    my $str = shift;
    # IE sends wrong formatted value(i.e. "Thu, 03 Dec 2009 01:46:32 GMT; length=17936")
    $str =~ s/;.*$//;
    return $str;
}

1;

__END__

=head1 NAME

Plack::Middleware::ConditionalGET - Middleware to enable conditional GET

=head1 SYNOPSIS

  builder {
      enable "ConditionalGET";
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
