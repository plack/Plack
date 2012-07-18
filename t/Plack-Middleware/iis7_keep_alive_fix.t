use strict;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use Plack::Middleware::IIS7KeepAliveFix;


my $app=Plack::Middleware::IIS7KeepAliveFix->wrap(
sub {
    my $env = shift;


    my $location='/go/?'.join('|', (0..1000));
      return [ 302, [
        'Content-Type' => 'text/html',
        'Content-Length' => 285,
        'Location' => $location,
      ],[qq~<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>Moved</title>
  </head>
  <body>
     <p>This item has moved <a href="$location">here</a>.</p>
  </body>
</html>~] ];
});


test_psgi(app=>$app,client=> sub {
    my $cb = shift;

    my $res = $cb->(GET "/");

    ok(!$res->content);
    ok(!$res->content_length);
    ok(!$res->content_type);
});

done_testing;

