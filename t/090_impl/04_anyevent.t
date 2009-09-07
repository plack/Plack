use strict;
use warnings;
use Test::More;
use Test::Requires qw(AnyEvent);

use Plack;
use Plack::Impl::AnyEvent;
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

            my $server = Plack::Impl::AnyEvent->new(
                port => $port,
                host => '127.0.0.1',
                app  => $handler,
            );
            $server->run;
            AnyEvent->condvar->recv;
        },
    );
}


