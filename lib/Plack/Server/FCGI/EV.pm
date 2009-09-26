package Plack::Server::FCGI::EV;

use strict;
use warnings;

use Plack::Util;
use EV;
use FCGI::EV;
use Plack::Server::FCGI::EV::Handler;
use Data::Dumper;

sub new {
    my ( $class, %args ) = @_;

    my $self = bless {}, $class;
    $self->{host} = delete $args{host} || undef;
    $self->{port} = delete $args{port} || undef;

    $self;
}

sub run {
    my ($self, $app) = @_;
    my $sock = IO::Socket::INET->new(
        LocalAddr => $self->{host},
        LocalPort => $self->{port},
        ReuseAddr => 1,
        Proto     => 'tcp',
        Listen    => 10,
        Blocking  => 0,
    ) or die "cannot open fcgi server";
    
    $ENV{SERVER_PORT} = $self->{port},
    $ENV{SERVER_NAME} = $self->{host},
    # warn Dumper \%ENV;

    # warn $sock;

    my $handler_class = 'Plack::Server::FCGI::EV::Handler';
    $handler_class->psgi_app($app);
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

sub run_loop {
    EV::loop;
}

1;
