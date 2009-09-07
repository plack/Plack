use strict;
use warnings;
use Test::More tests => 1;
use Plack::Request::Upload;

my $upload = Plack::Request::Upload->new(
    filename => '/tmp/foo/bar/hoge.txt',
);
is $upload->basename, 'hoge.txt';
