use strict;
use warnings;
use Test::More;
use Test::Requires qw( CGI::ExceptionManager );
use Plack::Middleware::StackTrace;

my $handler = Plack::Middleware::StackTrace->wrap(sub { die "orz" });
my $res = $handler->(+{});
is scalar(@$res), 3;
is $res->[0], 500;
is_deeply $res->[1], ['Content-Type' => 'text/html; charset=utf-8'];
like $res->[2]->[0], qr/orz/;

done_testing;

