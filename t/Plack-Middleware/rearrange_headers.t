use strict;
use Test::More;
use Plack::Builder;
use Plack::Middleware qw(RearrangeHeaders);

my $app = sub {
    return [ 200, [
        'Last-Modified' => 'Wed, 23 Sep 2009 13:36:33 GMT',
        'Content-Type' => 'text/plain',
        'ETag' => 'foo bar',
      ], [ 'Hello Foo' ] ];
  };

$app = builder {
    enable Plack::Middleware::RearrangeHeaders;
    $app;
};

# Don't use Plack::Test since it uses HTTP::Headers to reorder itself
my $res = $app->({});

is_deeply $res->[1], [
    'ETag' => 'foo bar',
    'Content-Type' => 'text/plain',
    'Last-Modified' => 'Wed, 23 Sep 2009 13:36:33 GMT',
];

done_testing;
