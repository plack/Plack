use strict;
use warnings;
use Test::More;
use Plack::Response;
use Test::Requires qw( HTTP::Headers );

my $hdrs = HTTP::Headers->new;
$hdrs->header('Content-Type' => 'text/plain');

{
    my $res = Plack::Response->new(200, $hdrs, []);
    is_deeply $res->finalize, [200, ['Content-Type' => 'text/plain'], []];
}

{
    my $res = Plack::Response->new(200);
    $res->headers($hdrs);
    is_deeply $res->finalize, [200, ['Content-Type' => 'text/plain'], []];
}

done_testing;
