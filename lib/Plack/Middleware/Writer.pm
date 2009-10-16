package Plack::Middleware::Writer;
use strict;
no warnings;
use Carp;
use Plack::Util;
use IO::Handle::Util;
use Scalar::Util qw(weaken);
use parent qw(Plack::Middleware);

sub call {
    my ( $self, $env ) = @_;

    my $res = $self->app->($env);
    return $res if $env->{'psgi.streaming'};

    if ( ref($res) eq 'CODE' ) {
        my $ret;

        $res->(sub {
            my $write = shift;

            if ( @$write == 2 ) {
                my ( $closed, @body );

                $ret = [ @$write, \@body ];

                # two copies because we weaken the one that is closed over
                my $writer;
                my $ref_up = $writer = Plack::Util::inline_object(
                    poll_cb => sub {
                        my $cb = shift;

                        until ( $closed ) {
                            $cb->($writer);
                        }
                    },
                    write => sub {
                        push @body, $_[0];
                    },
                    close => sub {
                        $closed = 1;
                    }
                );

                weaken($writer);

                return $writer;
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
