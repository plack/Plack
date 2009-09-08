use strict;
use warnings;
use CGI;
use Plack::Adapter::CGI;
use Test::More;

{
    package CallableTest;
    use base 'Plack::Adapter::Callable';
    sub call {
        my($self, $env) = @_;
        ::is $env->{REMOTE_ADDR}, '192.168.1.1';
        ::is $env->{REQUEST_METHOD}, 'POST';
        my $fh = $env->{'psgi.input'};
        my $body = do { local $/; <$fh> };
        ::is $body, 'hello=world';

        my $eh = $env->{'psgi.errors'};
        print $eh "hello error\n";
        [
            200,
            [
                'X-Bar'          => 'Baz',
                'Content-Type'   => 'text/html; charset=utf-8',
                'Content-Length' => 4,
            ],
            [
                'TKSK',
            ],
        ];
    }
}

my $err;
$ENV{REQUEST_METHOD} = 'GET';
my $handler = Plack::Adapter::Callable->new('CallableTest')->handler;

open my $in, '<', \do { my $body = "hello=world" };
open my $errors, '>', \$err;
my $res = $handler->(
    +{
        'psgi.input'   => $in,
        REMOTE_ADDR    => '192.168.1.1',
        REQUEST_METHOD => 'POST',
        CONTENT_TYPE   => 'application/x-www-form-urlencoded',
        CONTENT_LENGTH => 11,
        'psgi.errors'  => $errors,
    }
);

is $res->[0], 200;
my $headers = +{@{$res->[1]}};
is $headers->{'X-Bar'}, 'Baz';
is $headers->{'Content-Type'}, 'text/html; charset=utf-8';
is $headers->{'Content-Length'}, 4;
is_deeply $res->[2], ['TKSK'];
is $ENV{REQUEST_METHOD}, 'GET', 'restored';

is $err, "hello error\n";

done_testing;
