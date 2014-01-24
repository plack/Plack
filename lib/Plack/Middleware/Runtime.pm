package Plack::Middleware::Runtime;
use strict;
use parent qw(Plack::Middleware);
use Plack::Util;
use Plack::Util::Accessor qw(header_name);
use Time::HiRes;

sub call {
    my($self, $env) = @_;

    my $start = [ Time::HiRes::gettimeofday ];
    my $res = $self->app->($env);
    my $header = $self->header_name || 'X-Runtime';

    $self->response_cb($res, sub {
        my $res = shift;
        my $req_time = sprintf '%.6f', Time::HiRes::tv_interval($start);
        Plack::Util::header_set($res->[1], $header, $req_time);
    });
}

1;

__END__

=head1 NAME

Plack::Middleware::Runtime - Sets an X-Runtime response header

=head1 SYNOPSIS

  enable "Runtime";

=head1 DESCRIPTION

Plack::Middleware::Runtime is a Plack middleware component that sets
the application's response time (in seconds) in the I<X-Runtime> HTTP response
header.

=head1 OPTIONS

=over 4

=item header_name

Name of the header. Defaults to I<X-Runtime>.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Time::HiRes> Rack::Runtime

=cut
