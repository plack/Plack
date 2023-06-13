use strict;
use warnings;
use utf8;
use Test::More;
use HTTP::Response;
use HTTP::Message::PSGI;

my $res = HTTP::Response->new(200, 'OK', ['Content-Length' => 3], 'Oh!');
is_deeply($res->to_psgi(), [
    200,
    ['Content-Length' => 3],
    ['Oh!']
]);
is_deeply(res_to_psgi($res), [
    200,
    ['Content-Length' => 3],
    ['Oh!']
]);

done_testing;

