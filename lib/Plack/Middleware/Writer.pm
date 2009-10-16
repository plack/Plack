package Plack::Middleware::Writer;
use strict;
no warnings;
use Carp;
use Plack::Util;
use Scalar::Util qw(weaken);
use parent qw(Plack::Middleware);

sub call {
    my ( $self, $env ) = @_;

    my $caller_supports_streaming = $env->{'psgi.streaming'};
    $env->{'psgi.streaming'} = Plack::Util::TRUE;

    my $res = $self->app->($env);
    return $res if $caller_supports_streaming;

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


# ex: set sw=4 et:

__PACKAGE__

__END__
