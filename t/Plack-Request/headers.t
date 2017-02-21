use strict;
use warnings;
use Test::More;

use Plack::Test;
use Plack::Request;
use HTTP::Request::Common;

my $app = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);

    return [200, ['Content-Type', 'text/plain'], [ $req->headers->as_string ]];
};    

my $test = Plack::Test->create($app);

my $res = $test->request(GET '/', 'Foo' => 1, 'foo-bar' => 1, 'www-authenticate' => 'basic bar');

like $res->content, qr/Foo: 1/, 'no uppercase';
like $res->content, qr/Foo-Bar: 1/, 'standard casing';
like $res->content, qr/Host: localhost/, 'standard casing';
like $res->content, qr/WWW-Authenticate: basic bar/, 'standard casing';

done_testing;
