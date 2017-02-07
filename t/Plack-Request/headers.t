use strict;
use warnings;
use Test::More;
use Plack::Test;
use Plack::Request;
use HTTP::Request::Common;

subtest 'basic' => sub {
    my $app = sub {
        my $req = Plack::Request->new(shift);
        my $headers = $req->header_parameters;
        is $headers->get('X-PLACK-REQUEST-HEADER-TEST'), 'foo';
        is $req->header('X-PLACK-REQUEST-HEADER-TEST'), 'foo';
        $req->new_response(200)->finalize;
    };

    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->(GET "/", 'X-PLACK-REQUEST-HEADER-TEST' => 'foo');
        ok $res->is_success;
    };
};

subtest 'multi-values' => sub {
    my $app = sub {
        my $req = Plack::Request->new(shift);
        my $headers = $req->header_parameters;
        is_deeply(
            [ $headers->get_all('X-PLACK-REQUEST-HEADER-TEST') ],
            [qw< foo bar baz >]
        );
        $req->new_response(200)->finalize;
    };

    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->(GET "/", 'X-PLACK-REQUEST-HEADER-TEST' => 'foo, bar, baz');
        ok $res->is_success;
    };
};

subtest 'multi-lines' => sub {
    my $app = sub {
        my $req = Plack::Request->new(shift);
        my $headers = $req->header_parameters;
        is_deeply(
            [ $headers->get_all('X-PLACK-REQUEST-HEADER-TEST') ],
            [qw< foo bar baz >]
        );
        $req->new_response(200)->finalize;
    };

    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->(
            GET "/",
            'X-PLACK-REQUEST-HEADER-TEST' => 'foo, bar',
            'X-PLACK-REQUEST-HEADER-TEST' => 'baz'
        );
        ok $res->is_success;
    };
};

done_testing;
