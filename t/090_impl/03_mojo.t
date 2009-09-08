use strict;
use warnings;
use Test::More;
use Test::Requires qw(Mojo::Server::Daemon);

use Plack;
use Plack::Impl::Mojo;
use Test::TCP;
use LWP::UserAgent;
use Mojo::Server::Daemon;
use Plack::Test;

Plack::Test->runtests(\&run_one);
done_testing();

sub run_one {
    my ($name, $reqgen, $handler, $test) = @_;
    note $name;

    test_tcp(
        client => sub {
            my $port = shift;

            my $ua = LWP::UserAgent->new();
            my $res = $ua->request($reqgen->($port));
            $test->($res, $port);
        },
        server => sub {
            my $port = shift;
            my $server = Plack::Impl::Mojo->new(
                host => "127.0.0.1",
                port => $port,
            );
            $server->run($handler);
        },
    );
}


