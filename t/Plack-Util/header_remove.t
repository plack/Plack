use strict;
use Test::More;
use Plack::Util;

{
    my $headers = [ Foo => 'bar', Bar => 'baz' ];
    Plack::Util::header_remove($headers, 'Foo');
    is_deeply $headers, [ Bar => 'baz' ];
}

{
    my $headers = [ Foo => 'bar', Bar => 'baz' ];
    Plack::Util::header_remove($headers, 'foo');
    is_deeply $headers, [ Bar => 'baz' ], 'header_remove case-insensitive';
}

done_testing;
