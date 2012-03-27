use strict;
use Test::More;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;

my $app = sub {
    my $env = shift;
    return sub {
      my $writer = shift->( [ 200, [
        'Content-Type' => 'text/plain',
      ] ] );
      $writer->write($_) for qw{Hello World};
      $writer->close;
    };
};

$app = builder { enable "Head"; $app };

test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(GET "/");
    is $res->content, "HelloWorld";

    $res = $cb->(HEAD "/");
    ok !$res->content;
    ok(!$res->content_length);
};

done_testing;

