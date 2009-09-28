use strict;
use warnings;
use Test::More tests => 15;

use Plack::Request::Upload;
use t::Utils;

my $req = req(
    CONTENT_LENGTH => 0,
    'psgi.input'   => *STDIN,
    CONTENT_TYPE   => 'text/plain'
);

# file1
$req->upload(foo => Plack::Request::Upload->new(filename => 'foo1.txt'));
is ref($req->upload('foo')), 'Plack::Request::Upload';
is $req->upload('foo')->filename, 'foo1.txt';

# file2
$req->upload(foo => Plack::Request::Upload->new(filename => 'foo2.txt'));
is ref($req->upload('foo')), 'Plack::Request::Upload';
is $req->upload('foo')->filename, 'foo1.txt';
my @files = $req->upload('foo');
is scalar(@files), 2;
is $files[0]->filename, 'foo1.txt';
is $files[1]->filename, 'foo2.txt';

# file3
$req->upload(foo => Plack::Request::Upload->new(filename => 'foo3.txt'));
is ref($req->upload('foo')), 'Plack::Request::Upload';
is $req->upload('foo')->filename, 'foo1.txt';
my @files2 = $req->upload('foo');
is scalar(@files2), 3;
is $files2[0]->filename, 'foo1.txt';
is $files2[1]->filename, 'foo2.txt';
is $files2[2]->filename, 'foo3.txt';

# no arguments
is join(', ', $req->upload()), 'foo';
$req->upload(bar => Plack::Request::Upload->new(filename => 'bar1.txt'));
is join(', ', sort { $a cmp $b } $req->upload()), 'bar, foo';

