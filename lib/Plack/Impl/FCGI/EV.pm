package Plack::Impl::FCGI::EV;

use strict;
use warnings;

use Plack::Util;
use Any::Moose;
use Plack::Util;
use EV;
use FCGI::EV;
use Plack::Impl::FCGI::EV::Handler;

has host => (
    is      => 'ro',
    isa     => 'Str',
    default => '127.0.0.1',
    trigger => sub {
        my $self = shift;
        utf8::downgrade( $self->{host} );
    },
);

has port => (
    is      => 'ro',
    isa     => 'Int',
    default => 1978,
    trigger => sub {
        my $self = shift;
        utf8::downgrade( $self->{port} );
    },
);

has psgi_app => (
    is  => 'rw',
    isa => 'CodeRef',
);

use Data::Dumper;

sub run {
    my $self = shift;
    my $sock = IO::Socket::INET->new(
        LocalAddr => $self->host,
        LocalPort => $self->port,
        ReuseAddr => 1,
        Proto     => 'tcp',
        Listen    => 10,
        Blocking  => 0,
    ) or die "cannot open fcgi server";
    
    $ENV{SERVER_PORT} = $self->port,
    $ENV{SERVER_NAME} = $self->host,
    # warn Dumper \%ENV;

    # warn $sock;

    my $handler_class = 'Plack::Impl::FCGI::EV::Handler';
    $handler_class->psgi_app($self->psgi_app);
    my $w = EV::io $sock, EV::READ, sub {
        my $client = $sock->accept;
        # warn $client;
        exit unless $client;
        $client->blocking(0);
        # warn $client;
        FCGI::EV->new( $client, $handler_class );
    };
    $self->{_sock} = $sock;
    $self->{_guard} = $w;
    return $self;
}

1;
