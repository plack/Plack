use strict;
use Plack::Server::CGI;
use Test::More;
use Test::Requires {
    'HTTP::Request::AsCGI' => 1.2,
};
use HTTP::Request;

my $app = sub {
    my $env = shift;
    return [ 200, [ "Content-Type", "text/plain" ], [ $env->{PATH_INFO} ] ];
};

my $req = HTTP::Request->new(GET => "http://localhost/foo");
my $cgi = HTTP::Request::AsCGI->new($req);
my $c = $cgi->setup;

my $warning;
{
    local $SIG{__WARN__} = sub { $warning .= "@_" };
    my $s = Plack::Server::CGI->new;
    $s->run($app);
}

my $res = $c->response;
is $res->content, "/foo";
like $warning, qr/deprecated/;

done_testing;



