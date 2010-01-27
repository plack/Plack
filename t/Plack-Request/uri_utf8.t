use strict;
use utf8;
use Plack::Request;
use HTTP::Request;
use HTTP::Message::PSGI;
use Test::More;

my $path = "/Платежи";

my $hreq = HTTP::Request->new(GET => "http://localhost" . $path);
my $req = Plack::Request->new($hreq->to_psgi);

is $req->uri->path, '/%D0%9F%D0%BB%D0%B0%D1%82%D0%B5%D0%B6%D0%B8';

done_testing;
