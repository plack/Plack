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
    my $headers = [ Foo => 'bar' ];
    is Plack::Util::header_get($headers, 'Foo'), 'bar';
}

{
    my $headers = [ Foo => 'bar' ];
    is Plack::Util::header_get($headers, 'foo'), 'bar', 'header_get case-insensitive'
}

{
    my $headers = [ Foo => 'bar', Bar => 'baz' ];
    Plack::Util::header_push($headers, Foo => 'quox');
    is_deeply $headers, [ Foo => 'bar', Bar => 'baz', Foo => 'quox' ];
}

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

{
    my $headers = [ Foo => 'bar', Bar => 'baz' ];
    is Plack::Util::header_exists($headers, 'Foo'), 1;
}

{
    my $headers = [ Foo => 'bar', Foo => 'baz' ];
    Plack::Util::header_set($headers, Foo => 'quox');
    is_deeply $headers, [ Foo => 'quox' ];
}

{
  my $headers = [];
  Plack::Util::header_set($headers, a_b_c => 'x');
  is_deeply $headers, [ 'a-b-c' => 'x' ];
  is Plack::Util::header_exists($headers, 'A-B-C'), 1;
  is Plack::Util::header_get($headers, 'A-B-C'), 'x';
  Plack::Util::header_push($headers, a_b_c => 'y');
  is_deeply $headers, [ 'a-b-c' => 'x', 'a-b-c' => 'y' ];
  Plack::Util::header_remove($headers, 'a-b-c');
  is_deeply $headers, [];
}

done_testing;

