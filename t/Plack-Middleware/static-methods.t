use strict;
use warnings;
use Test::More;
use Plack::Middleware::Static;
use Plack::Builder;
use Plack::Util;
use HTTP::Request::Common;
use HTTP::Response;
use Cwd;
use Plack::Test;

my $base = cwd;

Plack::MIME->add_type(".foo" => "text/x-fooo");

my $handler = builder {
    enable "Plack::Middleware::Static",
        path => sub { s!^/share/!!},
        root => "share",
        methods => [qw/ GET HEAD /];
    sub {
        [200, ['Content-Type' => 'text/plain', 'Content-Length' => 2], ['ok']]
    };
};

my %test = (
    client => sub {
        my $cb  = shift;


        {
            my $res = $cb->(GET "http://localhost/share/face.jpg");
            is $res->content_type, 'image/jpeg';
        }

        {
            my $res = $cb->(HEAD "http://localhost/share/face.jpg");
            is $res->content_type, 'image/jpeg';
        }

        {
            my $res = $cb->(POST "http://localhost/share/face.jpg");
            is $res->code, 405;
        }

},
    app => $handler,
);

test_psgi %test;

done_testing;
