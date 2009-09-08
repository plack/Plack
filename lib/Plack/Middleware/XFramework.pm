package Plack::Middleware::XFramework;
use strict;
use warnings;
use base qw/Plack::Middleware/;
__PACKAGE__->mk_accessors(qw/framework/);

sub call {
    my $self = shift;
    my $res = $self->code->( @_ );
    push @{$res->[1]}, 'X-Framework' => $self->framework;
    $res;
}

1;
