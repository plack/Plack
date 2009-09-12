use strict;
use warnings;
use CGI;
use CGI::Emulate::PSGI;
use Test::More;

my $err;
$ENV{REQUEST_METHOD} = 'GET';
my $handler = CGI::Emulate::PSGI->handler(
    sub {
        is $ENV{REMOTE_ADDR}, '192.168.1.1';
        is $ENV{REQUEST_METHOD}, 'POST';
        my $q = CGI->new();
        is $q->param('hello'), 'world';
        print "Content-Type: text/html; charset=utf-8\r\n";
        print "X-Foo: Bar\r\n";
        print "Content-Length: 4\r\n";
        print "\r\n";
        print "KTKR";
        print STDERR "hello error\n";
    }
);

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
is $headers->{'X-Foo'}, 'Bar';
is $headers->{'Content-Type'}, 'text/html; charset=utf-8';
is $headers->{'Content-Length'}, 4;
is_deeply $res->[2], ['KTKR'];
is $ENV{REQUEST_METHOD}, 'GET', 'restored';

is $err, "hello error\n";

done_testing;

