use strict;
use warnings;
use Test::More;
use Test::Requires qw(HTTP::Server::Simple);
use Test::TCP;

use Plack;
use Plack::Loader;
use CGI::Emulate::PSGI;
use CGI;
use LWP::UserAgent;

test_tcp(
    client => sub {
        my $port = shift;
        my $ua = LWP::UserAgent->new;
        my $res = $ua->get("http://localhost:$port/");
        is $res->code, 200;
        is $res->content, 'Hello World';
    },
    server => sub {
        my $port = shift;
        Plack::Loader->load('ServerSimple', port => $port, host => "127.0.0.1")->run(
            CGI::Emulate::PSGI->handler(
                sub {
                    print "X-Foo: bar\r\n";
                    print "\r\n";
                    print "Hello World";
                }
            )
        );
    },
);

done_testing();

