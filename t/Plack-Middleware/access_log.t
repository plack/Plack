use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;
use POSIX;

my $log;

my $test = sub {
    my ($format, $handlers) = @_;
    return sub {
        my $req = shift;
        my $app = builder {
            enable "Plack::Middleware::AccessLog",
                logger => sub { $log = "@_" },
                format => $format,
                $handlers ? ( handlers => $handlers) : ();
            sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ 'OK' ] ] };
        };
        test_psgi $app, sub { $_[0]->($req) };
    };
};

{
    my $req = GET "http://example.com/";
    $req->header("Host" => "example.com", "X-Forwarded-For" => "192.0.2.1");

    my $fmt = "%P %{Host}i %p %{X-Forwarded-For}i %{Content-Type}o %{%m %y}t %v";
    $test->($fmt)->($req);
    chomp $log;
    my $month_year = POSIX::strftime('%m %y', localtime);
    is $log, "$$ example.com 80 192.0.2.1 text/plain [$month_year] example.com";
}

{
    $test->("%D")->(GET "/");
    chomp $log;
    is $log, '-';
}

{
    my $req = GET "http://example.com/";
    my $fmt = "%r == %m %U%q %H";
    $test->($fmt)->($req);
    chomp $log;
    my ($r, $rs) = split / == /, $log;
    is $r, $rs;
}

{
    my $req = GET "http://example.com/foo?bar=baz";
    my $fmt = "%r == %m %U%q %H";
    $test->($fmt)->($req);
    chomp $log;
    my ($r, $rs) = split / == /, $log;
    is $r, $rs;
}

{
    # this is not a great example as we should probably be using
    # Plack::Middleware::ReverseProxy instead, but it demonstrates the use of
    # an arbitrary sub
    my $fmt = '%h %{HTTP_X_FORWARDED_FOR|REMOTE_ADDR}x';
    my $handlers = {
        x => sub {
            my ($args, $type, $h, $env) = @_;
            my ($main, $alt) = split('\|', $args);
            $env->{$main} // $env->{$alt};
        },
    };

    my $req1 = GET('/example.com', 'X-Forwarded-For' => '456');
    $test->($fmt, $handlers)->($req1);
    chomp $log;
    is($log, '127.0.0.1 456', 'handler sub called and main header used');

    my $req2 = GET('/example.com');
    $test->($fmt, $handlers)->($req2);
    chomp $log;
    is($log, '127.0.0.1 127.0.0.1', 'handler sub called and backup header is used');
}


done_testing;
