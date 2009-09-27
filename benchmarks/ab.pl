#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Plack::Loader;
use Test::TCP;
use Getopt::Long;
use URI;
use String::ShellQuote;

my $app = 'eg/dot-psgi/Hello.psgi';
my $ab  = 'ab -n 100 -c 10 -k';
my $url = 'http://127.0.0.1/';

my @backends = grep eval "require Plack::Server::$_; 1",
    qw( AnyEvent Standalone ServerSimple Mojo::Prefork Coro Danga::Socket );

warn "Testing implementations: ", join(", ", @backends), "\n";

GetOptions(
    'app=s'   => \$app,
    'bench=s' => \$ab,
    'url=s'   => \$url,
) or die;

&main;

sub main {
    print "app: $app\n";
    print "ab:  $ab\n";
    for my $server_class (@backends) {
        run_one($server_class);
    }
}

sub run_one {
    my $server_class = shift;
    my $port = Test::TCP::empty_port();
    print "-- server: $server_class\n";

    my $pid = fork();
    if ($pid > 0) { # parent
        Test::TCP::wait_port($port);
        my $uri = URI->new($url);
        $uri->port($port);
        $uri = shell_quote($uri);
        print `$ab $uri | grep 'Requests per '`;
        kill 'TERM' => $pid;
        wait();
    } else {
        my $handler = Plack::Util::load_psgi $app;
        my $server = Plack::Loader->load($server_class, port => $port);
        $server->run($handler);
        $server->run_loop if $server->can('run_loop'); # run event loop
    }
}


