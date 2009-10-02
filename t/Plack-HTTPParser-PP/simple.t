use Test::More tests => 6;

use Plack::HTTPParser::PP;
*parse_http_request = \&Plack::HTTPParser::PP::parse_http_request;

my $req;
my %env;

$req = "GET /abc?x=y HTTP/1.0\r\n\r\n";
%env = ();
is(parse_http_request($req, \%env), length($req), 'simple get');
is_deeply(\%env, {
    PATH_INFO       => '/abc',
    QUERY_STRING    => 'x=y',
    REQUEST_METHOD  => "GET",
    SCRIPT_NAME     => '',
    SERVER_PROTOCOL => 'HTTP/1.0',
    REQUEST_URI     => '/abc?x=y',
}, 'result of GET /');

$req = <<"EOT";
POST /hoge HTTP/1.1\r
Content-Type: text/plain\r
Content-Length: 15\r
Host: example.com\r
User-Agent: hoge\r
\r
EOT
%env = ();
is(parse_http_request($req, \%env), length($req), 'POST');
is_deeply(\%env, {
    CONTENT_LENGTH  => 15,
    CONTENT_TYPE    => 'text/plain',
    HTTP_HOST       => 'example.com',
    HTTP_USER_AGENT => 'hoge',
    PATH_INFO       => '/hoge',
    REQUEST_METHOD  => "POST",
    REQUEST_URI     => '/hoge',
    QUERY_STRING    => '',
    SERVER_PROTOCOL => 'HTTP/1.1',
    SCRIPT_NAME     => '',
}, 'result of GET with headers');

$req = <<"EOT";
GET / HTTP/1.0\r
Foo: \r
Foo: \r
  abc\r
 de\r
Foo: fgh\r
\r
EOT
%env = ();
is(parse_http_request($req, \%env), length($req), 'multiline header');
is_deeply(\%env, {
    HTTP_FOO        => ',   abc de, fgh',
    PATH_INFO       => '/',
    QUERY_STRING    => '',
    REQUEST_METHOD  => 'GET',
    REQUEST_URI     => '/',
    SCRIPT_NAME     => '',
    SERVER_PROTOCOL => 'HTTP/1.0',
}, 'multiline');
