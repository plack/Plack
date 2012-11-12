package Plack::Middleware::BufferedStreaming;
use strict;
no warnings;
use Carp;
use Plack::Util;
use Plack::Util::Accessor qw(force);
use Scalar::Util qw(weaken);
use parent qw(Plack::Middleware);

sub call {
    my ( $self, $env ) = @_;

    my $caller_supports_streaming = $env->{'psgi.streaming'};
    $env->{'psgi.streaming'} = Plack::Util::TRUE;

    my $res = $self->app->($env);
    return $res if $caller_supports_streaming && !$self->force;

    if ( ref($res) eq 'CODE' ) {
        my $ret;

        $res->(sub {
            my $write = shift;

            if ( @$write == 2 ) {
                my @body;

                $ret = [ @$write, \@body ];

                return Plack::Util::inline_object(
                    write => sub { push @body, $_[0] },
                    close => sub { },
                );
            } else {
                $ret = $write;
                return;
            }
        });

        return $ret;
    } else {
        return $res;
    }
}

1;

__END__

=head1 NAME

Plack::Middleware::BufferedStreaming - Enable buffering for non-streaming aware servers

=head1 SYNOPSIS

  enable "BufferedStreaming";

=head1 DESCRIPTION

Plack::Middleware::BufferedStreaming is a PSGI middleware component
that wraps the application that uses C<psgi.streaming> interface to
run on the servers that do not support the interface, by buffering the
writer output to a temporary buffer.

This middleware doesn't do anything and bypass the application if the
server supports C<psgi.streaming> interface, unless you set C<force>
option (see below).

=head1 OPTIONS

=over 4

=item force

Force enable this middleware only if the container supports C<psgi.streaming>.

=back

=head1 AUTHOR

Yuval Kogman

Tatsuhiko Miyagawa

=cut
