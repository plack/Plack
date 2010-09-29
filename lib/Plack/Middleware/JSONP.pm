package Plack::Middleware::JSONP;
use strict;
use parent qw(Plack::Middleware);
use Plack::Util;
use URI::Escape ();

use Plack::Util::Accessor qw/callback_key/;

sub call {
    my($self, $env) = @_;
    my $res = $self->app->($env);
    $self->response_cb($res, sub {
        my $res = shift;
        if (defined $res->[2] && ref $res->[2] eq 'ARRAY' && @{$res->[2]} == 1) {
            my $h = Plack::Util::headers($res->[1]);
            my $callback_key = $self->callback_key || 'callback';
            if ($h->get('Content-Type') =~ m!/(?:json|javascript)! &&
                $env->{QUERY_STRING} =~ /(?:^|&)$callback_key=([^&]+)/) {
                my $cb = URI::Escape::uri_unescape($1);
                if ($cb =~ /^[\w\.\[\]]+$/) {
                    my $jsonp = "$cb($res->[2][0])";
                    $res->[2] = [ $jsonp ];
                    $h->set('Content-Length', length $jsonp);
                    $h->set('Content-Type', 'text/javascript');
                }
            }
        }
    });
}

1;

__END__

=head1 NAME

Plack::Middleware::JSONP - Wraps JSON response in JSONP if callback parameter is specified

=head1 SYNOPSIS

    enable "JSONP", callback_key => 'jsonp';

=head1 DESCRIPTION

Plack::Middleware::JSONP wraps JSON response, which has Content-Type
value either C<text/javascript> or C<application/json> as a JSONP
response which is specified with the C<callback> query parameter. The 
name of the parameter can be set while enabling the middleware.

This middleware only works with an application response with content
body set as a single element array ref and doesn't touch the response
otherwise.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plack>

=cut

