use strict;
use warnings;
use FindBin;
use Test::More;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;

my $build_res = sub {
  my ( $code, $msg ) = @_;
  return sub {
    my $res = shift;
    my $w = $res->([ $code, [ 'Content-Type', 'text/plain' ] ]);
    $w->write($msg);
    $w->close;
  }
};

my $app = sub {
    my $env = shift;
    if ($env->{PATH_INFO} eq '/status/403') {
      return $build_res->(403, 'Permission denied');
    } elsif ($env->{PATH_INFO} eq '/') {
      return $build_res->(200, 'Hello');
    } elsif ($env->{PATH_INFO} eq '/status/500') {
      return $build_res->(500, 'Server error');
    }
    return $build_res->(404, 'Not found');
};

my $log;
my $handler = builder {
    enable "Plack::Middleware::ErrorDocument",
        500 => "$FindBin::Bin/errors/500.html";
    enable "Plack::Middleware::ErrorDocument",
        404 => "/errors/404.html", subrequest => 1;
    enable 'Plack::Middleware::HTTPExceptions';
    enable "Plack::Middleware::Static",
        path => qr{^/errors}, root => $FindBin::Bin;
    $app;
};

test_psgi app => $handler, client => sub {
    my $cb = shift;
    {
        my $res = $cb->(GET "http://localhost/");
        is $res->code, 200;

        $res = $cb->(GET "http://localhost/status/500");
        is $res->code, 500;
        like $res->content, qr/fancy 500/;

        $res = $cb->(GET "http://localhost/status/404");
        is $res->code, 404;
        like $res->header('content_type'), qr!text/html!;
        like $res->content, qr/fancy 404/;
    }
};

done_testing;
