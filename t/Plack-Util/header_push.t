use strict;
use Test::More;
use Plack::Util;

{
    my $headers = [];
    Plack::Util::header_push($headers, Foo => 'quox');
    is_deeply $headers, [ Foo => 'quox' ], 'push to empty headers';
}

{
    my $headers = [ Bar => 'baz' ];
    Plack::Util::header_push($headers, Foo => 'quox');
    is_deeply $headers, [ Bar => 'baz', Foo => 'quox' ], 'push to non-empty headers';
}

{
    my $headers = [ Foo => 'bar', Bar => 'baz' ];
    Plack::Util::header_push($headers, Foo => 'quox');
    is_deeply $headers, [ Foo => 'bar', Bar => 'baz', Foo => 'quox' ], 'push with previous header values';
}

done_testing;
