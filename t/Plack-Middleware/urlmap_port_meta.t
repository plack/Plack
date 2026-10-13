use strict;
use Test::More;
use Plack::App::URLMap;

my $make_app = sub {
    my $name = shift;
    sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ $name ] ] };
};

my $app = Plack::App::URLMap->new;
$app->map("http://example.com/" => $make_app->("host"));
$app->map("/" => $make_app->("default"));

my $env = sub {
    my($host, $port) = @_;
    return {
        HTTP_HOST   => $host,
        SERVER_NAME => 'localhost',
        SERVER_PORT => $port,
        PATH_INFO   => '/',
        SCRIPT_NAME => '',
    };
};

is $app->($env->('example.com:8080', 8080))->[2][0], 'host', 'port is stripped from Host';

# SERVER_PORT containing regex metacharacters must be matched literally
my $res = eval { $app->($env->('example.com:(', '(')) };
is $@, '', 'regex metacharacters in SERVER_PORT do not die';
is $res->[2][0], 'host', 'literal port is stripped from Host';

$res = eval { $app->($env->('example.com:80', '.*')) };
is $res->[2][0], 'default', 'SERVER_PORT is not used as a pattern';

done_testing;
