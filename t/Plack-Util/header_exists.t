use strict;
use Test::More;
use Plack::Util;

{
    my $headers = [];
    ok !Plack::Util::header_exists($headers, 'Foo'), 'no headers';
}

{
    my $headers = [ Baz => 'bar', Bar => 'baz' ];
    ok !Plack::Util::header_exists($headers, 'Foo'), 'header does not exist';
}

{
    my $headers = [ Foo => 'bar', Bar => 'baz' ];
    ok Plack::Util::header_exists($headers, 'Foo'), 'header is first';
}

{
    my $headers = [ Bar => 'foo', Foo => 'baz' ];
    ok Plack::Util::header_exists($headers, 'Foo'), 'header is last';
}

{
    my $headers = [ Bar => 'foo', Foo => 'baz', Baz => 'quux' ];
    ok Plack::Util::header_exists($headers, 'Foo'), 'header in middle';
}

{
    my $headers = [ Bar => 'foo', Foo => 'baz', Baz => 'foo', Foo => 'quux', Quux => 'bar' ];
    ok Plack::Util::header_exists($headers, 'Foo'), 'header occurs multiple times';
}

{
    my $headers = [ Foo => 'bar', Bar => 'baz' ];
    ok Plack::Util::header_exists($headers, 'foo'), 'case-insensitive';
}

done_testing;
