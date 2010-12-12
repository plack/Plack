use strict;
use warnings;
use FindBin;
use Test::More;
use Plack::Response;
use URI;
use File::Temp;

sub r($) {
    my $res = Plack::Response->new(200);
    $res->body(@_);
    return $res->finalize->[2];
}

is_deeply r "Hello World", [ "Hello World" ];
is_deeply r [ "Hello", "World" ], [ "Hello", "World" ];

{
    open my $fh, "$FindBin::Bin/body.t";
    is_deeply r $fh, $fh;
}

{
    my $foo = "bar";
    open my $io, "<", \$foo;
    is_deeply r $io, $io;
}

{
    my $uri = URI->new("foo"); # stringified object
    is_deeply r $uri, [ $uri ];
}

{
    my $tmp = File::Temp->new; # File::Temp has stringify method, but it is-a IO::Handle.
    is_deeply r $tmp, $tmp;
}

done_testing;

