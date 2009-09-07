use strict;
use warnings;
use Test::More;
use Test::Requires qw(HTTP::Server::Simple);

use Plack;
use Plack::Impl::ServerSimple;
use Test::TCP;
use LWP::UserAgent;
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

            my $server = Plack::Impl::ServerSimple->new($port);
            $server->host("127.0.0.1");
            $server->psgi_app($handler);
            $server->run;
        },
    );
}


