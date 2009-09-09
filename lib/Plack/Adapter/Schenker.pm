package Plack::Adapter::Schenker;
use strict;
use warnings;

sub new {
    my($class, $app) = @_;
    bless { app => $app }, $class;
}

sub handler {
    my $self = shift;

    my $engine = HTTP::Engine->new(
        interface => {
            module => 'PSGI',
            request_handler => sub { Schenker::request_handler(@_) },
        }
    );

    Schenker::init;
    return sub { Schenker::Engine->run(@_) };
}

1;
