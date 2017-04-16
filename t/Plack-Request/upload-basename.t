use strict;
use warnings;
use Test::More tests => 3;
use Plack::Request::Upload;

my $upload = Plack::Request::Upload->new(
    filename => '/tmp/foo/bar/hoge.txt',
);
is $upload->basename, 'hoge.txt';

my $upload2 = Plack::Request::Upload->new(
    filename => '/tmp/foo/bar/hoge[1].txt',
);
is $upload2->basename, 'hoge_1_.txt';

my $upload3 = Plack::Request::Upload->new(
    filename => "/tmp/foo/bar/baz\x{2015}qux.txt",
);
is $upload3->basename, "baz_qux.txt";

