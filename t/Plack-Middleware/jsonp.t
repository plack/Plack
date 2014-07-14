use strict;
use Test::More;
use Plack::Test;
use Plack::Builder;

my @json = ('{"foo":', '"bar"}');
my $json = join '', @json;

my @tests = (
    {
        callback_key => 'json.p',
        app          => sub {
            return [ 200, [ 'Content-Type' => 'application/json' ], [@json] ];
        },
    },
    {
        app => sub {
            return sub {
                my $respond = shift;
                $respond->(
                    [ 200, [ 'Content-Type' => 'application/json' ], [$json] ]
                );
            };
        },
    }
);

for my $test ( @tests ) {
    my $app = $test->{app};

    if ( exists $test->{callback_key} ) {
        $app = builder {
            enable "Plack::Middleware::JSONP", callback_key => $test->{callback_key};
            $app;
        };
    }
    else {
        $app = builder {
            enable "Plack::Middleware::JSONP";
            $app;
        };
    }
    my $callback_key = $test->{callback_key} || 'callback';

    test_psgi app => $app, client => sub {
        my $cb = shift;

        my $res = $cb->(HTTP::Request->new(GET => 'http://localhost/'));
        is $res->content_type, 'application/json';
        is $res->content, $json;
        $res = $cb->(HTTP::Request->new(GET => 'http://localhost/?'.$callback_key.'=foo'));
        is $res->content_type, 'text/javascript';
        is $res->content, "/**/foo($json)";
    };
}

done_testing;

