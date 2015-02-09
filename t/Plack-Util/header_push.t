use strict;
use Test::More;
use Plack::Util;

{
    my $headers = [ Foo => 'bar', Bar => 'baz' ];
    Plack::Util::header_push($headers, Foo => 'quox');
    is_deeply $headers, [ Foo => 'bar', Bar => 'baz', Foo => 'quox' ];
}

done_testing;
