package Plack::Middleware::XSendfile;
use strict;
use warnings;
use parent qw(Plack::Middleware);

use Plack::Util;
use Scalar::Util;
use Plack::Util::Accessor qw( variation );

sub call {
    my $self = shift;
    my $env  = shift;

    my $res = $self->app->($env);
    $self->response_cb($res, sub {
        my $res = shift;
        my($status, $headers, $body) = @$res;
        return unless defined $body;

        if (Scalar::Util::blessed($body) && $body->can('path')) {
            my $type = $self->_variation($env) || '';
            my $h = Plack::Util::headers($headers);
            if ($type && !$h->exists($type)) {
                if ($type eq 'X-Accel-Redirect') {
                    my $path = $body->path;
                    my $url = $self->map_accel_path($env, $path);
                    $h->set($type => $url) if $url;
                    $body = [];
                } elsif ($type eq 'X-Sendfile' or $type eq 'X-Lighttpd-Send-File') {
                    my $path = $body->path;
                    $h->set($type => $path) if defined $path;
                    $body = [];
                } else {
                    $env->{'psgi.errors'}->print("Unknown x-sendfile variation: $type");
                }
            }
        }

        @$res = ( $status, $headers, $body );
    });
}

sub map_accel_path {
    my($self, $env, $path) = @_;

    if (my $mapping = $env->{HTTP_X_ACCEL_MAPPING}) {
        my($internal, $external) = split /=/, $mapping, 2;
        $path =~ s!^\Q$internal\E!$external!i;
    }

    return $path;
}

sub _variation {
    my($self, $env) = @_;
    $self->variation || $env->{'plack.xsendfile.type'} || $env->{HTTP_X_SENDFILE_TYPE};
}

1;

__END__

=head1 NAME

Plack::Middleware::XSendfile - Sets X-Sendfile (or a like) header for frontends

=head1 SYNOPSIS

  enable "Plack::Middleware::XSendfile";

=head1 DESCRIPTION

You should use L<IO::File::WithPath> or L<Plack::Util>'s
C<set_io_path> to add C<path> method to an IO object in the body.

See L<http://github.com/rack/rack-contrib/blob/master/lib/rack/contrib/sendfile.rb>
for the frontend configuration.

=head1 AUTHOR

Tatsuhiko Miyagawa

=cut
