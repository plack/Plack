use strict;
use warnings;
use Test::More;
use Plack;
use Plack::Impl::FCGI::EV;
use Test::TCP;
use LWP::UserAgent;
use Plack::Test;
use t::FCGIUtils;
# use AnyEvent;

use Data::Dumper;

my $lighty_port;
my $fcgi_port;

test_lighty_external(
   sub {
       ($lighty_port, $fcgi_port) = @_;
       Plack::Test->runtests(\&run_one);
       done_testing();
    }
);


sub run_one {
    my ($name, $reqgen, $handler, $test) = @_;
    note $name;
    test_tcp(
        client => sub {
            # my $port = shift;
            my $port = $lighty_port;
            my $ua = LWP::UserAgent->new();
            my $res = $ua->request($reqgen->($port));
            $test->($res, $port);
        },
        server => sub {
            my $port = shift;
            my $server = Plack::Impl::FCGI::EV->new(host => '127.0.0.1', port => $port);
            $server->run($handler);
            $server->run_loop;
        },
        port => $fcgi_port
    );
}


