use strict;
use warnings;
use Test::More;
use Plack::Response;

{
    my $res = Plack::Response->new(302);
    is $res->status, 302;
    is $res->code, 302;
}

{
    my $res = Plack::Response->new(200, [ 'Content-Type' => 'text/plain' ]);
    is $res->content_type, 'text/plain';
}

{
    my $res = Plack::Response->new(200, { 'Content-Type' => 'text/plain' });
    is $res->content_type, 'text/plain';
}

{
    my $res = Plack::Response->new(200);
    $res->content_type('image/png');
    is $res->content_type, 'image/png';
}

{
    my $res = Plack::Response->new(200);
    $res->header('X-Foo' => "bar");
    is $res->header('X-Foo'), "bar";
}

done_testing;
