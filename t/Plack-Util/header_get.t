use strict;
use Test::More;
use Plack::Util;

{
    my $headers = [ Foo => 'bar' ];
    is Plack::Util::header_get($headers, 'Foo'), 'bar';
}

{
    my $headers = [ Foo => 'bar' ];
    is Plack::Util::header_get($headers, 'foo'), 'bar', 'header_get case-insensitive'
}

done_testing;
