use strict;
use warnings;
use Test::More;

use Plack::Middleware::FixPathInfoMultipleSlashes;
use URI::Escape;
use URI;

my %env = (
          'psgi.multiprocess' => 1,
          'SCRIPT_NAME' => '/fastcgi',
          'PATH_INFO' => '/foo/bar/baz',
          'REQUEST_METHOD' => 'GET',
          'psgi.multithread' => '',
          'SCRIPT_FILENAME' => '/var/folders/9y/f64sy2xx3vnb8ddv4w1g498m0000gn/T/utzt7PlANx/fastcgi',
          'SERVER_SOFTWARE' => 'lighttpd/1.4.30',
          'HTTP_TE' => 'deflate,gzip;q=0.3',
          'REMOTE_PORT' => '54624',
          'QUERY_STRING' => '',
          'HTTP_USER_AGENT' => 'libwww-perl/6.04',
          'FCGI_ROLE' => 'RESPONDER',
          'psgi.streaming' => 1,
          'GATEWAY_INTERFACE' => 'CGI/1.1',
          'psgi.version' => [
                              1,
                              1
                            ],
          'DOCUMENT_ROOT' => '/var/folders/9y/f64sy2xx3vnb8ddv4w1g498m0000gn/T/utzt7PlANx/',
          'psgi.run_once' => '',
          'PATH_TRANSLATED' => '/var/folders/9y/f64sy2xx3vnb8ddv4w1g498m0000gn/T/utzt7PlANx//foo/bar/baz',
          'SERVER_NAME' => '127.0.0.1',
          'HTTP_CONNECTION' => 'TE, close',
          'SERVER_PORT' => '50992',
          'REDIRECT_STATUS' => '200',
          'REMOTE_ADDR' => '127.0.0.1',
          'SERVER_PROTOCOL' => 'HTTP/1.1',
          'REQUEST_URI' => '/fastcgi//foo///bar/baz',
          'psgi.nonblocking' => '',
          'SERVER_ADDR' => '127.0.0.1',
          'psgi.url_scheme' => 'http',
          'psgix.harakiri' => 1,
          'HTTP_X_PLACK_TEST' => '35',
          'HTTP_HOST' => '127.0.0.1:50992',
);

sub test_fix {
    my ($input_env) = @_;

    my $mangled_env;
    Plack::Middleware::FixPathInfoMultipleSlashes->wrap(sub {
        my ($env) = @_;
        $mangled_env = $env;
        return [ 200, ['Content-Type' => 'text/plain'], [''] ];
    })->($input_env);

    return $mangled_env;
}

my $fixed_env = test_fix({ %env });

is($fixed_env->{PATH_INFO}, '//foo///bar/baz', 'check PATH_INFO');

done_testing;
