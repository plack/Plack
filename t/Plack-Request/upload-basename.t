use strict;
use warnings;
use Test::More;
use Plack::Request::Upload;

my $upload = Plack::Request::Upload->new(
    filename => '/tmp/foo/bar/hoge.txt',
);
is $upload->basename, 'hoge.txt';

for my $filename ('..', '.', '', 'x/', 'x/..', 'x\\..', '../..', '/') {
    my $upload = Plack::Request::Upload->new(filename => $filename);
    my $basename = $upload->basename;
    ok length $basename, "basename for '$filename' is not empty";
    ok $basename ne '.' && $basename ne '..', "basename for '$filename' is not a dot directory";
}

is( Plack::Request::Upload->new(filename => '..foo')->basename, '..foo' );
is( Plack::Request::Upload->new(filename => '.htaccess')->basename, '.htaccess' );

done_testing;
