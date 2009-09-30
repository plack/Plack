use strict;
use Test::More;
use Plack::Util;

{
    my $headers = [ Foo => 'bar' ];

    my $h = Plack::Util::headers($headers);
    $h->set(Bar => 'baz');

    is_deeply $headers, [ Foo => 'bar', Bar => 'baz' ];
    is_deeply $h->headers, [ Foo => 'bar', Bar => 'baz' ];

    is $h->get('Foo'), 'bar';
    $h->push('Foo' => 'xxx');
    is $h->get('Foo'), 'bar';
    my @v = $h->get('Foo');
    is_deeply \@v, [ 'bar', 'xxx' ];

    ok $h->exists('Bar');
    $h->remove('Bar');
    ok ! $h->exists('Bar');

    is_deeply $headers, $h->headers;
}

done_testing;
