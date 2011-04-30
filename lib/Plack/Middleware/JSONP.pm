package Plack::Middleware::JSONP;
use strict;
use parent qw(Plack::Middleware);
use Plack::Util;
use URI::Escape ();

use Plack::Util::Accessor qw/callback_key/;

sub prepare_app {
    my $self = shift;
    unless (defined $self->callback_key) {
        $self->callback_key('callback');
    }
}

sub call {
    my($self, $env) = @_;
    my $res = $self->app->($env);
    $self->response_cb($res, sub {
        my $res = shift;
        if (defined $res->[2]) {
            my $h = Plack::Util::headers($res->[1]);
            my $callback_key = $self->callback_key;
            if ($h->get('Content-Type') =~ m!/(?:json|javascript)! &&
                $env->{QUERY_STRING} =~ /(?:^|&)$callback_key=([^&]+)/) {
                my $cb = URI::Escape::uri_unescape($1);
                if ($cb =~ /^[\w\.\[\]]+$/) {
                    my $body;
                    Plack::Util::foreach($res->[2], sub { $body .= $_[0] });
                    my $jsonp = "$cb($body)";
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

This middleware only works with a non-streaming response, and doesn't
touch the response otherwise.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plack>

=cut

