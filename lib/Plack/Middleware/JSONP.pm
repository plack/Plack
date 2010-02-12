package Plack::Middleware::JSONP;
use strict;
use parent qw(Plack::Middleware);
use Plack::Util;
use URI::Escape ();

sub call {
    my($self, $env) = @_;
    my $res = $self->app->($env);
    $self->response_cb($res, sub {
        my $res = shift;

        my $h = Plack::Util::headers($res->[1]);
        if ($h->get('Content-Type') =~ m!/(?:json|javascript)! &&
                $env->{QUERY_STRING} =~ /(?:^|&)callback=([^&]+)/) {
            # TODO: support callback params other than 'callback'
            my $cb = URI::Escape::uri_unescape($1);

            if ($cb =~ /^[\w\.\[\]]+$/) {
                $h->set('Content-Type', 'text/javascript');

                # The filter to transform the body into a JSONP response.
                my $isnt_first = 0;
                return sub {
                    return ( $isnt_first++ ? ''    : "$cb(" )
                         . ( defined $_[0] ? $_[0] : ')'    );
                };
            }
        }
    });
}

1;

__END__

=head1 NAME

Plack::Middleware::JSONP - Wraps JSON response in JSONP if callback parameter is specified

=head1 DESCRIPTION

Plack::Middleware::JSONP wraps JSON response, which has Content-Type
value either C<text/javascript> or C<application/json> as a JSONP
response which is specified with the C<callback> query parameter.

Since this middleware removes the Content-Length header to rewrite the content body, you may also want to enable Plack::Middleware::ContentLength.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plack> L<Plack::Middleware::ContentLength>

=cut

