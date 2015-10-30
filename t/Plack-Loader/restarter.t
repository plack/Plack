use strict;
use Test::More;
use Test::TCP;
use Test::Requires qw(LWP::UserAgent);
use HTTP::Request::Common;
use Plack::Loader::Restarter;

plan skip_all => "author test only" unless $ENV{AUTHOR_TESTING};

$SIG{__WARN__} = sub { diag @_ };

my @return_bodies = ('Hi first', 'Hi second', 'Hi third');
my @restartertestfiles = ('t/restartertestfile1.pl', 't/restartertestfile2.pl');
unlink $_ for @restartertestfiles;

my $builder = sub {
    my $idx = 0;
    for my $file (@restartertestfiles) {
        $idx++ if -e $file;
    }

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

        touch($restartertestfiles[0]);
        sleep 2;
        wait_port($port);

        is $cb->()->content, $return_bodies[1];

        touch($restartertestfiles[1]);
        sleep 2;
        wait_port($port);

        is $cb->()->content, $return_bodies[2];
    },
    server => sub {
        my $port = shift;

        my $loader = Plack::Loader::Restarter->new;
        my $server = $loader->auto(port => $port, host => '127.0.0.1');
        $loader->preload_app($builder);
        $loader->watch('t');
        $loader->run($server);
    },
);

sub touch {
    my $file = shift;
    open my $fh, ">", $file or die $!;
    print $fh time;
    close $fh;
}

unlink $_ for @restartertestfiles;

done_testing;
