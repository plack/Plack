use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More tests => 74;
use Catalyst::Test 'TestApp';
use Catalyst::Request;

my $creq;

# test that the path can be changed
{
    ok( my $response = request('http://localhost/engine/request/uri/change_path'), 'Request' );
    ok( $response->is_success, 'Response Successful 2xx' );
    ok( eval '$creq = ' . $response->content, 'Unserialize Catalyst::Request' );
    like( $creq->uri, qr{/my/app/lives/here$}, 'URI contains new path' );
}

# test that path properly removes the base location
{
    ok( my $response = request('http://localhost/engine/request/uri/change_base'), 'Request' );
    ok( $response->is_success, 'Response Successful 2xx' );
    ok( eval '$creq = ' . $response->content, 'Unserialize Catalyst::Request' );
    like( $creq->base, qr{/new/location}, 'Base URI contains new location' );
    is( $creq->path, 'engine/request/uri/change_base', 'URI contains correct path' );
}

# test that base + path is correct
{
    ok( my $response = request('http://localhost/engine/request/uri'), 'Request' );
    ok( $response->is_success, 'Response Successful 2xx' );
    ok( eval '$creq = ' . $response->content, 'Unserialize Catalyst::Request' );
    is( $creq->base . $creq->path, $creq->uri, 'Base + Path ok' );
}

# test base is correct for HTTPS URLs
SKIP:
{
    if ( $ENV{CATALYST_SERVER} ) {
        skip 'Using remote server', 5;
    }
    
    local $ENV{HTTPS} = 'on';
    ok( my $response = request('https://localhost/engine/request/uri'), 'HTTPS Request' );
    ok( $response->is_success, 'Response Successful 2xx' );
    ok( eval '$creq = ' . $response->content, 'Unserialize Catalyst::Request' );
    is( $creq->base, 'https://localhost/', 'HTTPS base ok' );
    is( $creq->uri, 'https://localhost/engine/request/uri', 'HTTPS uri ok' );
}

# test that we can use semi-colons as separators
{
    my $parameters = {
        a => [ qw/1 2/ ],
        b => 3,
    };
    
    ok( my $response = request('http://localhost/engine/request/uri?a=1;a=2;b=3'), 'Request' );
    ok( $response->is_success, 'Response Successful 2xx' );
    ok( eval '$creq = ' . $response->content, 'Unserialize Catalyst::Request' );
    is( $creq->uri->query, 'a=1;a=2;b=3', 'Query string ok' );
    is_deeply( $creq->parameters, $parameters, 'Parameters ok' );
}

# test that query params are unescaped properly
{
    ok( my $response = request('http://localhost/engine/request/uri?text=Catalyst%20Rocks'), 'Request' );
    ok( $response->is_success, 'Response Successful 2xx' );
    ok( eval '$creq = ' . $response->content, 'Unserialize Catalyst::Request' );
    is( $creq->uri->query, 'text=Catalyst%20Rocks', 'Query string ok' );
    is( $creq->parameters->{text}, 'Catalyst Rocks', 'Unescaped param ok' );
}

# test that uri_with adds params
{
    ok( my $response = request('http://localhost/engine/request/uri/uri_with'), 'Request' );
    ok( $response->is_success, 'Response Successful 2xx' );
    ok( !defined $response->header( 'X-Catalyst-Param-a' ), 'param "a" ok' );
    is( $response->header( 'X-Catalyst-Param-b' ), '1', 'param "b" ok' );
    is( $response->header( 'X-Catalyst-Param-c' ), '--notexists--', 'param "c" ok' );
    unlike($response->header ('X-Catalyst-query'), qr/c=/, 'no c in return');
}

# test that uri_with adds params (and preserves)
{
    ok( my $response = request('http://localhost/engine/request/uri/uri_with?a=1'), 'Request' );
    ok( $response->is_success, 'Response Successful 2xx' );
    is( $response->header( 'X-Catalyst-Param-a' ), '1', 'param "a" ok' );
    is( $response->header( 'X-Catalyst-Param-b' ), '1', 'param "b" ok' );
    is( $response->header( 'X-Catalyst-Param-c' ), '--notexists--', 'param "c" ok' );
    unlike($response->header ('X-Catalyst-query'), qr/c=/, 'no c in return');
}

# test that uri_with replaces params (and preserves)
{
    ok( my $response = request('http://localhost/engine/request/uri/uri_with?a=1&b=2&c=3'), 'Request' );
    ok( $response->is_success, 'Response Successful 2xx' );
    is( $response->header( 'X-Catalyst-Param-a' ), '1', 'param "a" ok' );
    is( $response->header( 'X-Catalyst-Param-b' ), '1', 'param "b" ok' );
    is( $response->header( 'X-Catalyst-Param-c' ), '--notexists--', 'param "c" deleted ok' );
    unlike($response->header ('X-Catalyst-query'), qr/c=/, 'no c in return');
}

# test that uri_with replaces params (and preserves)
{
    ok( my $response = request('http://localhost/engine/request/uri/uri_with_object'), 'Request' );
    ok( $response->is_success, 'Response Successful 2xx' );
    like( $response->header( 'X-Catalyst-Param-a' ), qr(https?://localhost[^/]*/), 'param "a" ok' );
}

# test that uri_with is utf8 safe
{
    ok( my $response = request("http://localhost/engine/request/uri/uri_with_utf8"), 'Request' );
    ok( $response->is_success, 'Response Successful 2xx' );
    like( $response->header( 'X-Catalyst-uri-with' ), qr/%E2%98%A0$/, 'uri_with ok' );
}

# test with undef -- no warnings should be thrown
{
    ok( my $response = request("http://localhost/engine/request/uri/uri_with_undef"), 'Request' );
    ok( $response->is_success, 'Response Successful 2xx' );
    is( $response->header( 'X-Catalyst-warnings' ), 0, 'no warnings emitted' );
}

# more tests with undef - should be ignored
{
    my $uri = "http://localhost/engine/request/uri/uri_with_undef_only";
    my ($check) = $uri =~ m{^http://localhost(.+)}; # needed to work with remote servers
    ok( my $response = request($uri), 'Request' );
    ok( $response->is_success, 'Response Successful 2xx' );
    like( $response->header( 'X-Catalyst-uri-with' ), qr/$check$/, 'uri_with ok' );

    # try with existing param
    $uri = "$uri?x=1";
    ($check) = $uri =~ m{^http://localhost(.+)}; # needed to work with remote servers
    $check =~ s/\?/\\\?/g;
    ok( $response = request($uri), 'Request' );
    ok( $response->is_success, 'Response Successful 2xx' );
    like( $response->header( 'X-Catalyst-uri-with' ), qr/$check$/, 'uri_with ok' );
}

{
    my $uri = "http://localhost/engine/request/uri/uri_with_undef_ignore";
    my ($check) = $uri =~ m{^http://localhost(.+)}; # needed to work with remote servers
    ok( my $response = request($uri), 'Request' );
    ok( $response->is_success, 'Response Successful 2xx' );
    like( $response->header( 'X-Catalyst-uri-with' ), qr/$check\?a=1/, 'uri_with ok' );

    # remove an existing param
    ok( $response = request("${uri}?b=1"), 'Request' );
    ok( $response->is_success, 'Response Successful 2xx' );
    like( $response->header( 'X-Catalyst-uri-with' ), qr/$check\?a=1/, 'uri_with ok' );

    # remove an existing param, leave one, and add a new one
    ok( $response = request("${uri}?b=1&c=1"), 'Request' );
    ok( $response->is_success, 'Response Successful 2xx' );
    is( $response->header( 'X-Catalyst-Param-a' ), '1', 'param "a" ok' );
    ok( !defined $response->header( 'X-Catalyst-Param-b' ),'param "b" ok' );
    is( $response->header( 'X-Catalyst-Param-c' ), '1', 'param "c" ok' );
}

# Test an overridden uri method which calls the base method, SmartURI does this.
SKIP:
{
    if ( $ENV{CATALYST_SERVER} ) {
        skip 'Using remote server', 2;
    }
 
    require TestApp::RequestBaseBug;
    TestApp->request_class('TestApp::RequestBaseBug');
    ok( my $response = request('http://localhost/engine/request/uri'), 'Request' );
    ok( $response->is_success, 'Response Successful 2xx' );
    TestApp->request_class('Catalyst::Request');
}
