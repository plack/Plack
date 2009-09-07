use strict;
use warnings;
use Plack::Impl::CGI;
use Plack::Middleware::XFramework;
use Test::More;

my $handler = Plack::Middleware::XFramework->new(
    framework => 'Dog',
    code => sub {
        [200, [], ['ok']]
    }
);
my $res = $handler->(+{});
is_deeply $res, [200, ['X-Framework' => 'Dog'], ['ok']];

done_testing;

