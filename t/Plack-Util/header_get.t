use strict;
use Test::More;
use Plack::Util;

{
    my $headers = [];
    is Plack::Util::header_get($headers, 'Foo'), undef, 'empty headers, scalar';
}

{
    my $headers = [];
    is_deeply [ Plack::Util::header_get($headers, 'Foo') ], [], 'empty headers, list';
}

{
    my $headers = [ Foo => 'bar' ];
    is Plack::Util::header_get($headers, 'Foo'), 'bar', 'header exists, scalar';
}

{
    my $headers = [ Foo => 'bar' ];
    is_deeply [ Plack::Util::header_get($headers, 'Foo') ], [ 'bar' ], 'header exists, list';
}

{
    my $headers = [ Foo => 'bar' ];
    is Plack::Util::header_get($headers, 'foo'), 'bar', 'case-insensitive'
}

done_testing;
