use strict;
use Test::More;
use Plack::Util;

{
    my $headers = [];
    Plack::Util::header_remove($headers, 'Foo');
    is_deeply $headers, [], 'empty headers';
}

{
    my $headers = [ Bar => 'baz' ];
    Plack::Util::header_remove($headers, 'Foo');
    is_deeply $headers, [ Bar => 'baz' ], 'other headers only';
}

{
    my $headers = [ Foo => 'bar', Bar => 'foo' ];
    Plack::Util::header_remove($headers, 'Foo');
    is_deeply $headers, [ Bar => 'foo' ], 'header is first';
}

{
    my $headers = [ Bar => 'foo', Foo => 'bar' ];
    Plack::Util::header_remove($headers, 'Foo');
    is_deeply $headers, [ Bar => 'foo' ], 'header is last';
}

{
    my $headers = [ Bar => 'foo', Foo => 'baz', Baz => 'quux' ];
    Plack::Util::header_remove($headers, 'Foo');
    is_deeply $headers, [ Bar => 'foo', Baz => 'quux' ], 'header in middle';
}

{
    my $headers = [ Bar => 'foo', Foo => 'baz', Baz => 'foo', Foo => 'quux', Quux => 'bar' ];
    Plack::Util::header_remove($headers, 'Foo');
    is_deeply $headers, [ Bar => 'foo', Baz => 'foo', Quux => 'bar' ], 'header occurs multiple times';
}

{
    my $headers = [ Foo => 'bar', Bar => 'baz' ];
    Plack::Util::header_remove($headers, 'foo');
    is_deeply $headers, [ Bar => 'baz' ], 'case-insensitive';
}

done_testing;
