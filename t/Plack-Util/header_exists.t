use strict;
use Test::More;
use Plack::Util;

{
    my $headers = [ Foo => 'bar', Bar => 'baz' ];
    is Plack::Util::header_exists($headers, 'Foo'), 1;
}

done_testing;
