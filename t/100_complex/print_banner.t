use strict;
use warnings;
use Test::More;
use Test::Requires qw(HTTP::Server::Simple Net::Server::Coro);
use Test::TCP;

use Plack;
use Plack::Loader;
use CGI::Emulate::PSGI;
use CGI;
use LWP::UserAgent;

my @data = (
    'AnyEvent'     => "OKAY http://127.0.0.1:10001/\n",
    'Coro'         => "OKAY http://127.0.0.1:10001/\n",
    'Standalone'   => "OKAY http://127.0.0.1:10001/\n",
    'ServerSimple' => "OKAY http://127.0.0.1:10001/\n",
);

while (my ($impl_class, $msg) = splice(@data, 0, 2)) {
    diag $impl_class;
    test_tcp(
        client => sub {
            my $port = shift;
            my $ua = LWP::UserAgent->new;
            my $res = $ua->get("http://127.0.0.1:$port/");
            is $res->code, 200;
            is $res->content, $msg;
        },
        server => sub {
            my $port = shift;
            open local(*STDOUT), '>', \my $out or die $!;
            my $impl = Plack::Loader->load($impl_class, port => $port, host => "127.0.0.1", print_banner => sub { print "OKAY http://$_[0]:$_[1]/\n" });
            $impl->run(
                sub {
                    my $env = shift;
                    [200, [], [$out]]
                }
            );
            $impl->run_loop if $impl->can('run_loop');
        },
    );
}

done_testing();

