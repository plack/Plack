use strict;
use warnings;
use Test::More;
use Test::Requires qw( CGI::ExceptionManager );
use Plack::Impl::CGI;
use Plack::Middleware::DebugScreen;

my $handler = enable Plack::Middleware::DebugScreen sub { die "orz" };
my $res = $handler->(+{});
is scalar(@$res), 3;
is $res->[0], 500;
is_deeply $res->[1], ['Content-Type' => 'text/html; charset=utf-8'];
like $res->[2]->[0], qr/orz/;

done_testing;

