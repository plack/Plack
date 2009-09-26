use strict;
use warnings;
use Test::More;
use Test::Requires qw(FCGI);
use Plack;
use Plack::Server::FCGI;
use Test::TCP;
use LWP::UserAgent;
use FindBin;
use Plack::Test;
use t::FCGIUtils;
# use AnyEvent;

$Plack::Test::BaseDir = "$FindBin::Bin/..";

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
            my $server = Plack::Server::FCGI->new(
                host        => '127.0.0.1',
                port        => $port,
                manager     => '',
                keep_stderr => 1,
            );
            $server->run($handler);
        },
        port => $fcgi_port
    );
}


