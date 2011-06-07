use strict;
use warnings;
use Test::More;
use Plack::Response;
use URI;

{
    my $res = Plack::Response->new;
    $res->redirect('http://www.google.com/');
    is $res->location, 'http://www.google.com/';
    is $res->code, 302;

    is_deeply $res->finalize, [ 302, [ 'Location' => 'http://www.google.com/' ], [] ];
}

{
    my $res = Plack::Response->new;
    $res->redirect('http://www.google.com/', 301);
    is_deeply $res->finalize, [ 301, [ 'Location' => 'http://www.google.com/' ], [] ];
}

{
    my $uri_invalid = "http://www.google.com/\r\nX-Injection: true\r\n\r\nHello World";
    my $uri_valid   = URI->new($uri_invalid)->as_string;

    my $res = Plack::Response->new;
    $res->redirect($uri_invalid, 301);
    is_deeply $res->finalize, [ 301, [ 'Location' => $uri_valid ], [] ];
}

done_testing;
