use strict;
use warnings;
use Test::More tests => 3;
use Plack::Request::Upload;

my $upload = Plack::Request::Upload->new(
    filename => '/tmp/foo/bar/baz-qux.txt',
);
is $upload->raw_basename, 'baz-qux.txt';

my $upload2 = Plack::Request::Upload->new(
    filename => '/tmp/foo/bar/baz-qux[1].txt',
);
is $upload2->raw_basename, 'baz-qux[1].txt';

my $upload3 = Plack::Request::Upload->new(
    filename => "/tmp/foo/bar/baz\x{2015}qux.txt",
);
is $upload3->raw_basename, "baz\x{2015}qux.txt";
