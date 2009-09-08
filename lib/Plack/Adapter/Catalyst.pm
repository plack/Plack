package Plack::Adapter::Catalyst;
use strict;
use warnings;

sub new {
    my($class, $app) = @_;
    bless { app => $app }, $class;
}

sub handler {
    my $self = shift;
    $self->{app}->setup_engine('PSGI');
    return sub { $self->{app}->run(@_) };
}

1;
