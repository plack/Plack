use strict;
use warnings;
use Plack::Impl::CGI;
use Plack::Middleware::DebugScreen;
use Test::More;

my $handler = Plack::Middleware::DebugScreen->new(
    code => sub {
        die "orz";
    }
);
my $res = $handler->(+{});
is scalar(@$res), 3;
is $res->[0], 500;
is_deeply $res->[1], ['Content-Type' => 'text/html; charset=utf-8'];
like $res->[2], qr/orz/;

done_testing;

