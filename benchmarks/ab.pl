#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Plack::Loader;
use Test::TCP;
use Getopt::Long;

my $app = 'eg/dot-psgi/Hello.psgi';
my $ab  = 'ab -n 100 -c 10 -k';

my %backends = (
    AnyEvent        => 'AnyEvent',
    'AnyEvent::HTTPD' => 'AnyEvent::HTTPD',
    Standalone      => 0,
    ServerSimple    => 'HTTP::Server::Simple',
    'Mojo::Prefork' => 'Mojo',
    Coro            => 'Coro',
);

my @backends;
for my $impl (sort keys %backends) {
    my $req = $backends{$impl};
    push @backends, $impl if !$req or eval "require $req; 1";
}

warn "Testing implementations: ", join(", ", @backends), "\n";

GetOptions(
    'app=s'   => \$app,
    'bench=s' => \$ab,
) or die;

&main;

sub main {
    print "app: $app\n";
    print "ab:  $ab\n";
    for my $impl_class (@backends) {
        run_one($impl_class);
    }
}

sub run_one {
    my $impl_class = shift;
    my $port = Test::TCP::empty_port();
    print "-- impl_class: $impl_class\n";

    my $pid = fork();
    if ($pid > 0) { # parent
        Test::TCP::wait_port($port);
        print `$ab http://127.0.0.1:$port/ | grep 'Requests per '`;
        kill 'TERM' => $pid;
        wait();
    } else {
        my $handler = load_handler(Cwd::cwd() . "/". $app) or die ($! || $@);
        my $impl = Plack::Loader->load($impl_class, port => $port);
        $impl->run($handler);
        $impl->run_loop if $impl->can('run_loop'); # run event loop
    }
}

sub load_handler {
    my $file = shift;
    return do $file;
}

