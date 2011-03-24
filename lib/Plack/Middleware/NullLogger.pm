package Plack::Middleware::NullLogger;
use strict;
use parent qw/Plack::Middleware/;

sub call {
    my($self, $env) = @_;
    $env->{'psgix.logger'} = sub { };
    $self->app->($env);
}

1;

__END__

=head1 NAME

Plack::Middleware::NullLogger - Send logs to /dev/null

=head1 SYNOPSIS

  enable "NullLogger";

=head1 DESCRIPTION

NullLogger is a middleware component that receives logs and does
nothing but discarding them. Might be useful to shut up all the logs
from frameworks in one shot.

=head1 AUTHOR

Tatsuhiko Miyagawa

=cut
