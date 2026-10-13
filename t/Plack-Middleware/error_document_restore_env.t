use strict;
use warnings;
use FindBin;
use Test::More;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;

my @lines;
my $inner_env;

my $handler = builder {
    enable "AccessLog", format => '%r %>s', logger => sub { push @lines, $_[0] };
    enable sub {
        my $app = shift;
        sub { $inner_env = $_[0]; $app->($_[0]) };
    };
    enable "ErrorDocument", 404 => "/errors/404.html", subrequest => 1;
    enable "Static", path => qr{^/errors}, root => $FindBin::Bin;

    sub {
        my $env = shift;
        my $status = ($env->{PATH_INFO} =~ m!status/(\d+)!)[0] || 200;
        [ $status, [ 'Content-Type' => 'text/plain' ], [ "Error: $status" ] ];
    };
};

test_psgi app => $handler, client => sub {
    my $cb = shift;

    my $res = $cb->(POST "http://localhost/status/404?q=1", [ foo => 'bar' ]);
    is $res->code, 404;
    like $res->content, qr/fancy 404/;

    is $inner_env->{REQUEST_METHOD}, 'POST';
    is $inner_env->{PATH_INFO}, '/status/404';
    is $inner_env->{QUERY_STRING}, 'q=1';
    is $inner_env->{REQUEST_URI}, '/status/404?q=1';
    ok $inner_env->{CONTENT_LENGTH}, 'CONTENT_LENGTH is restored';

    is scalar @lines, 1;
    like $lines[0], qr{^POST /status/404\?q=1 HTTP/1\.1 404}, 'access log records the original request';
};

done_testing;
