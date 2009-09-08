#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More tests => 13;
use Catalyst::Test 'TestApp';

use Catalyst::Request;
use CGI::Simple::Cookie;
use HTTP::Headers;
use HTTP::Request::Common;
use URI;

{
    my $creq;

    my $request = GET( 'http://localhost/dump/request',
        'Cookie' => 'Catalyst=Cool; Cool=Catalyst', );

    ok( my $response = request($request), 'Request' );
    ok( $response->is_success, 'Response Successful 2xx' );
    is( $response->content_type, 'text/plain', 'Response Content-Type' );
    like( $response->content, qr/'Catalyst::Request'/,
        'Content is a serialized Catalyst::Request' );
    ok( eval '$creq = ' . $response->content, 'Unserialize Catalyst::Request' );
    isa_ok( $creq, 'Catalyst::Request' );
    isa_ok( $creq->cookies->{Catalyst}, 'CGI::Simple::Cookie',
            'Cookie Catalyst' );
    is( $creq->cookies->{Catalyst}->name, 'Catalyst', 'Cookie Catalyst name' );
    is( $creq->cookies->{Catalyst}->value, 'Cool', 'Cookie Catalyst value' );
    isa_ok( $creq->cookies->{Cool}, 'CGI::Simple::Cookie', 'Cookie Cool' );
    is( $creq->cookies->{Cool}->name,  'Cool',     'Cookie Cool name' );
    is( $creq->cookies->{Cool}->value, 'Catalyst', 'Cookie Cool value' );

    my $cookies = {
        Catalyst => $creq->cookies->{Catalyst},
        Cool     => $creq->cookies->{Cool}
    };

    is_deeply( $creq->cookies, $cookies, 'Cookies' );
}
