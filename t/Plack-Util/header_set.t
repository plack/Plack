use strict;
use Test::More;
use Plack::Util;

{
    my $headers = [ Foo => 'bar' ];
    Plack::Util::header_set($headers, Bar => 'baz');
    is_deeply $headers, [ Foo => 'bar', Bar => 'baz' ];
}

{
    my $headers = [ Foo => 'bar' ];
    Plack::Util::header_set($headers, Foo => 'baz');
    is_deeply $headers, [ Foo => 'baz' ];
}

{
    my $headers = [ Foo => 'bar' ];
    Plack::Util::header_set($headers, foo => 'baz');
    is_deeply $headers, [ Foo => 'baz' ], 'header_set case-insensitive';
}

{
    my $headers = [ Foo => 'bar', Foo => 'baz' ];
    Plack::Util::header_set($headers, Foo => 'quox');
    is_deeply $headers, [ Foo => 'quox' ];
}

done_testing;
