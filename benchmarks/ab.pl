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
    qw( AnyEvent Standalone Standalone::Prefork ServerSimple Coro Danga::Socket POE );

warn "Testing implementations: ", join(", ", @backends), "\n";

GetOptions(
    'a|app=s'   => \$app,
    'b|bench=s' => \$ab,
    'u|url=s'   => \$url,
) or die;

&main;

sub main {
    print <<EOF;
app: $app
ab:  $ab
URL: $url

EOF
    for my $server_class (@backends) {
        run_one($server_class);
    }
}

sub run_one {
    my $server_class = shift;
    print "-- server: $server_class\n";

    test_tcp(
        client => sub {
            my $port = shift;
            my $uri = URI->new($url);
            $uri->port($port);
            $uri = shell_quote($uri);
            print `$ab $uri | grep 'Requests per '`;
        },
        server => sub {
            my $port = shift;
            my $handler = Plack::Util::load_psgi $app;
            my $server = Plack::Loader->load($server_class, port => $port);
            $server->run($handler);
        },
    );
}


