use strict;
use Test::More;

use Plack::Middleware::Lint;
use HTTP::Message::PSGI qw(req_to_psgi);
use HTTP::Request;

my $app = sub {
    [ 200, [ 'Content-Type' => 'text/plain' ], [ "OK" ] ];
};

$app = Plack::Middleware::Lint->wrap($app);

my @good_env = (
    { PATH_INFO => '' },
);

my @bad_env = (
    [ { REQUEST_METHOD => undef }, qr/Missing env param: REQUEST_METHOD/ ],
    [ { REQUEST_METHOD => "foo" },, qr/Invalid env param: REQUEST_METHOD/ ],
    [ { PATH_INFO => 'foo' }, qr/PATH_INFO must begin with \// ],
    [ { SERVER_PORT => undef }, qr/Missing mandatory .*SERVER_PORT/ ],
    [ { SERVER_PROTOCOL => 'HTTP/x' }, qr/Invalid SERVER_PROTOCOL/ ],
    [ { "psgi.version" => 2 }, qr/psgi\.version should be ArrayRef/ ],
    [ { HTTP_CONTENT_TYPE => "text/plain" }, qr/HTTP_CONTENT_TYPE should not exist/ ],
);

for my $good (@good_env) {
    my $env = req_to_psgi( HTTP::Request->new(GET => "/") );
    eval {
        $app->({ %$env, %$good });
    };
    ok !$@;
}

for my $bad (@bad_env) {
    my($inject, $err) = @$bad;
    my $env = req_to_psgi( HTTP::Request->new(GET => "/") );
    eval {
        $app->({ %$env, %$inject });
    };
    like $@, $err, $err;
}

done_testing;
