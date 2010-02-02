package Plack::Middleware::HTTPExceptions;
use strict;
use parent qw(Plack::Middleware);

use Try::Tiny;
use Scalar::Util 'blessed';
use HTTP::Status ();

sub call {
    my($self, $env) = @_;

    my $res = try {
        $self->app->($env);
    } catch {
        $self->transform_error($_);
    };

    return $res;
}

sub transform_error {
    my($self, $e) = @_;

    my($code, $message);
    if (blessed $e && $e->can('code')) {
        $code = $e->code;
        $message =
            $e->can('as_string')       ? $e->as_string :
            overload::Method($e, '""') ? "$e"          : undef;
    } else {
        $code = 500;
    }

    $message ||= HTTP::Status::status_message($code);

    return [ $code, [ 'Content-Type' => 'text/plain', 'Content-Length' => length($message) ], [ $message ] ];
}

1;


