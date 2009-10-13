use strict;
use warnings;
use Plack::Builder;
use Test::More;

my $handler = builder {
    enable "Plack::Middleware::XFramework",
        framework => 'Dog';
    sub {
        [200, [], ['ok']]
    };
};

my $res = $handler->(+{});
is_deeply $res, [200, ['X-Framework' => 'Dog'], ['ok']];

done_testing;

