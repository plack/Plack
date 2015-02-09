use strict;
use Test::More;
use Test::Differences;
use Plack::Util;

{
    my $headers = [];
    Plack::Util::header_set($headers, Bar => 'baz');
    eq_or_diff $headers, [ Bar => 'baz' ], 'empty headers';
}

{
    my $headers = [ Foo => 'bar' ];
    Plack::Util::header_set($headers, Bar => 'baz');
    eq_or_diff $headers, [ Foo => 'bar', Bar => 'baz' ], 'other headers only';
}

{
    my $headers = [ Foo => 'bar' ];
    Plack::Util::header_set($headers, Foo => 'baz');
    eq_or_diff $headers, [ Foo => 'baz' ], 'one matching header';
}

{
    my $headers = [ Foo => 'bar', Foo => 'baz' ];
    Plack::Util::header_set($headers, Foo => 'quox');
    eq_or_diff $headers, [ Foo => 'quox' ], 'several matching headers';
}

{
    my $headers = [ Foo => 'bar' ];
    Plack::Util::header_set($headers, foo => 'baz');
    eq_or_diff $headers, [ Foo => 'baz' ], 'case-insensitive';
}

done_testing;
