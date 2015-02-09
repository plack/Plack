use strict;
use Test::More;
use Plack::Util;

{
    my $headers = [];
    Plack::Util::header_set($headers, Bar => 'baz');
    is_deeply $headers, [ Bar => 'baz' ], 'empty headers';
}

{
    my $headers = [ Foo => 'bar' ];
    Plack::Util::header_set($headers, Bar => 'baz');
    is_deeply $headers, [ Foo => 'bar', Bar => 'baz' ], 'other headers only';
}

{
    my $headers = [ Foo => 'bar' ];
    Plack::Util::header_set($headers, Foo => 'baz');
    is_deeply $headers, [ Foo => 'baz' ], 'one matching header';
}

{
    my $headers = [ Foo => 'bar', Foo => 'baz' ];
    Plack::Util::header_set($headers, Foo => 'quox');
    is_deeply $headers, [ Foo => 'quox' ], 'several matching headers';
}

{
    my $headers = [ Foo => 'bar' ];
    Plack::Util::header_set($headers, foo => 'baz');
    is_deeply $headers, [ Foo => 'baz' ], 'case-insensitive';
}

done_testing;
