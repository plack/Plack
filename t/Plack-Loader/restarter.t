use strict;
use Test::More;
use Test::TCP;
use LWP::UserAgent;
use HTTP::Request::Common;
use Plack::Loader::Restarter;

my @return_bodies = ('Hi first', 'Hi second', 'Hi third');
my @restartertestfiles = ('restartertestfile1', 'restartertestfile2');
unlink $_ for @restartertestfiles;

my $builder = sub {
    my $idx = 0;
    for ( @restartertestfiles ) {
        $idx++ if -f;
    }
    warn "idx: $idx";

    my $return_body = $return_bodies[$idx];
    my $app = sub {
        return [ 200, [], [ $return_body ] ];
    };
};



test_tcp(
    client => sub {
        my $port = shift;
        my $ua = LWP::UserAgent->new;
        my $cb = sub {
            my $req = HTTP::Request->new(GET => sprintf('http://127.0.0.1:%s/', $port));
            return $ua->request($req);
        };

        is $cb->()->content, $return_bodies[0];

        open my $wfh, '>', $restartertestfiles[0];
        sleep 1;
        wait_port($port);

        is $cb->()->content, $return_bodies[1];

        open my $wfh2, '>', $restartertestfiles[1];
        sleep 1;
        wait_port($port);

        is $cb->()->content, $return_bodies[2];
    },
    server => sub {
        my $port = shift;

        my $loader = Plack::Loader::Restarter->new;
        my $server = $loader->auto(port => $port);
        $loader->preload_app($builder);
        $loader->watch('.');
        $loader->run($server);
    },
);


unlink $_ for @restartertestfiles;

done_testing;


