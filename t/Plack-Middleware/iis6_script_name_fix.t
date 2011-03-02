use strict;
use warnings;
use Test::More;

use Plack::Middleware::IIS6ScriptNameFix;

my %env = (
    'SCRIPT_NAME' => '/koo/blurb',
    'PATH_INFO' => '/koo/blurb',
    'HTTP_ACCEPT' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'REQUEST_METHOD' => 'GET',
    'SCRIPT_FILENAME' => 'C:\\Foo\\script\\blurb',
    'INSTANCE_META_PATH' => '/LM/W3SVC/793536',
    'SERVER_SOFTWARE' => 'Microsoft-IIS/6.0',
    'AUTH_PASSWORD' => '',
    'AUTH_TYPE' => '',
    'HTTP_USER_AGENT' => 'Mozilla/5.0 (Windows; U; Windows NT 5.2; de; rv:1.9.0.4) Gecko/2008102920 Firefox/3.0.4 (.NET CLR 3.5.30729)',
    'REMOTE_PORT' => '1281',
    'QUERY_STRING' => '',
    'URL' => '/koo/blurb',
    'HTTP_ACCEPT_LANGUAGE' => 'de-de,de;q=0.8,en-us;q=0.5,en;q=0.3',
    'FCGI_ROLE' => 'RESPONDER',
    'HTTP_KEEP_ALIVE' => '300',
    'CONTENT_TYPE' => '',
    'LOCAL_ADDR' => '127.0.0.1',
    'GATEWAY_INTERFACE' => 'CGI/1.1',
    'HTTPS' => 'off',
    'DOCUMENT_ROOT' => 'C:\\Foo\\script',
    'REMOTE_HOST' => '127.0.0.1',
    'PATH_TRANSLATED' => 'C:\\Foo\\script\\blurb',
    'APPL_PHYSICAL_PATH' => 'C:\\Foo\\script\\',
    'SERVER_NAME' => '127.0.0.1',
    'HTTP_ACCEPT_ENCODING' => 'gzip,deflate',
    'HTTP_CONNECTION' => 'keep-alive',
    'INSTANCE_ID' => '793536',
    'CONTENT_LENGTH' => '0',
    'AUTH_USER' => '',
    'APPL_MD_PATH' => '/LM/W3SVC/793536/Root/koo',
    'HTTP_ACCEPT_CHARSET' => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
    'REMOTE_USER' => '',
    'SERVER_PORT_SECURE' => '0',
    'SERVER_PORT' => 83,
    'REMOTE_ADDR' => '127.0.0.1',
    'SERVER_PROTOCOL' => 'HTTP/1.1',
    'REQUEST_URI' => '/koo/blurb',
    'APP_POOL_ID' => 'DefaultAppPool',
    'HTTP_HOST' => '127.0.0.1:83'
);

sub test_fix {
    my ($input_env) = @_;

    my $mangled_env;
    Plack::Middleware::IIS6ScriptNameFix->wrap(sub {
        my ($env) = @_;
        $mangled_env = $env;
        return [ 200, ['Content-Type' => 'text/plain'], [''] ];
    })->($input_env);

    return $mangled_env;
}

my $fixed_env = test_fix({ %env });

is($fixed_env->{PATH_INFO}, '//blurb', 'check PATH_INFO');
is($fixed_env->{SCRIPT_NAME}, '/koo', 'check SCRIPT_NAME');

done_testing;
