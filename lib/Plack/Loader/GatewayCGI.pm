# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.

package Plack::Loader::GatewayCGI;

use strict;
use warnings;

our $VERSION = '0.0001';

use IO::Socket::INET;
use Plack::Request;
use LWP::UserAgent;

use parent qw( Plack::Loader );

our $LIVETIME = 90;

sub run {
    my ( $self, $server, $builder ) = @_;

    if ( $server->isa('Plack::Handler::CGI') || $server->isa('Plack::Server::CGI') ) {
        $server->run( $builder->() );
    }
    else {
        my $cgiserver       = $self->load('CGI');
        my ( $host, $port ) = $self->gethostandport( $server );
        my $proxy           = $self->make_proxy( $host, $port );

        if ( $self->live_server( $host, $port ) ) {
            $cgiserver->run( $proxy );
        }
        else {
            my $pid = fork();
            if ( $pid ) {
                $cgiserver->run( $proxy );
            }
            elsif ( $pid == 0 ) {
                $self->run_server( $server, $builder );
            }
            else {
                die "Cannot running backend server.";
            }
        }
    }
}

sub live_server {
    my ( $self, $host, $port ) = @_;

    my $sock = IO::Socket::INET->new(
        PeerAddr    => $host || '127.0.0.1',
        PeerHost    => $port,
        Proto       => 'tcp',
        Timeout     => 10,
    );

    if ( $sock ) {
        $sock->close;
        return 1;
    }

    return 0;
}

our %CONFIG_GETTER = (
    AnyEvent        => sub { return @{ $_[0] }{qw( host port )} },
    Coro            => sub { return @{ $_[0] }{qw( host port )} },
    POE             => sub { return @{ $_[0] }{qw( host port )} },
    ServerSimple    => sub { return @{ $_[0] }{qw( host port )} },
    Standalone      => sub {
        my ( $server ) = @_;
        if ( $server->can('_server') ) {
            return @{ $server->{'args'} }{qw( host port )},
        }
        else {
            return @{ $server }{qw( host port )},
        }
    },
);

sub gethostandport {
    my ( $self, $server ) = @_;

    for my $impl ( keys %CONFIG_GETTER ) {
        my @classes = (
            "Plack::Handler::${impl}",
            "Plack::Server::${impl}",
        );

        for my $class ( @classes ) {
            if ( $server->isa($class) ) {
                return $CONFIG_GETTER{$impl}->( $server );
            }
        }
    }

    die "Cannot getting server host and port.";
}

sub run_server {
    my ( $self, $server, $builder ) = @_;

    my $pid = fork;
    if ( $pid ) {
        sleep $LIVETIME;
        warn "Killing backend server (pid: ${pid})";
        kill INT => $pid;
        waitpid( $pid, 0 );
        warn "Killed backend server.";
    }
    elsif ( $pid == 0 ) {
        warn "Backend server start.";
        $server->run( $builder->() );
    }
    else {
        die "Cannot fork server killer";
    }
}

sub make_proxy {
    my ( $self, $host, $port ) = @_;
    my $ua  = LWP::UserAgent->new;

    return sub {
        my $req = Plack::Request->new(shift);

        for ( qw(   Connection Keep-Alive Proxy-Authenticate Proxy-Authorization
                    TE Trailers Transfer-Encoding Upgrade Proxy-Connection Public ) ) {
            $req->headers->remove_header($_);
        }

        $req->headers->scan(sub {
            my ( $key, $value ) = @_;
            $req->headers->remove_header($key);
        });

        my $uri = $req->uri;
           $uri->host( $host );
           $uri->port( $port );

        my $res = $ua->request( HTTP::Request->new(
            $req->method, $uri, $req->headers, $req->body,
        ) );

        return $req->new_response( $res->code, $res->headers, $res->content )->finalize;
    };
}

1;