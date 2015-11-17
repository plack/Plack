use strict;
use warnings;
use Test::More;
use Plack::Request;
use Plack::Test;
use HTTP::Request::Common;

my @temp_files = ();

my $app = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);

    isa_ok $req->uploads->{foo}, 'HASH';
    is $req->uploads->{foo}->{filename}, 'foo2.txt';

    my @files = $req->upload('foo');
    is scalar(@files), 2;
    is $files[0]->filename, 'foo1.txt';
    is $files[1]->filename, 'foo2.txt';
    ok -e $files[0]->tempname;

    is join(', ', sort { $a cmp $b } $req->upload()), 'bar, foo';

    for (qw(foo bar)) {
        my $temp_file = $req->upload($_)->path;
        ok -f $temp_file;
        push @temp_files, $temp_file;
    }

    is $req->parameters->{baz}, "quux";

    my $res = $req->new_response(200);

    undef $req; # Simulate when we instantiate Plack::Request multiple times

    # redo the test with the same $env
    $req = Plack::Request->new($env);
    @files = $req->upload('foo');
    is scalar(@files), 2;
    is $files[0]->filename, 'foo1.txt';
    ok -e $files[0]->tempname;

    $res->finalize;
};

test_psgi $app, sub {
    my $cb = shift;

    $cb->(POST "/", Content_Type => 'form-data', Content => [
             foo => [ "t/Plack-Request/foo1.txt" ],
             foo => [ "t/Plack-Request/foo2.txt" ],
             bar => [ "t/Plack-Request/foo1.txt" ],
             baz => "quux",
         ]);
};

# Check if the temp files got cleaned up properly
ok !-f $_ for @temp_files;

done_testing;

