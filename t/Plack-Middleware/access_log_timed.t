use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;
use Test::MockTime::HiRes qw(mock_time);
use Time::HiRes;

my $log;
my $handler = builder {
    enable "Plack::Middleware::AccessLog::Timed",
        logger => sub { $log .= "@_" };
    sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ 'OK' ] ] };
};

my $test_req = sub {
    my $req = shift;
    test_psgi app => $handler,
        client => sub {
        my $cb = shift;
        $cb->($req);
    };
};

{
    $test_req->(GET "http://localhost/");
    like $log, qr@^127\.0\.0\.1 - - \[.*?\] "GET / HTTP/1\.1" 200 2@;
}

{
    $log = "";
    $test_req->(POST "http://localhost/foo", { foo => "bar" });
    like $log, qr@^127\.0\.0\.1 - - \[.*?\] "POST /foo HTTP/1\.1" 200 2@;
}

{
    $log = "";
    $test_req->(GET "http://localhost/foo%20bar?baz=baz");
    like $log, qr@GET /foo%20bar\?baz=baz HTTP/1\.1@;
}

# Testing delayed responses

$log = "";
$handler = builder {
    enable "Plack::Middleware::AccessLog::Timed",
        logger => sub { $log .= "@_" };
    sub { 
        return sub { 
            $_[0]->( [ 200, [ 'Content-Type' => 'text/plain' ], [ 'OK' ] ] ) 
        } 
    };
};

$test_req = sub {
    my $req = shift;
    test_psgi app => $handler,
        client => sub {
        my $cb = shift;
        $cb->($req);
    };
};

{
    $test_req->(GET "http://localhost/");
    like $log, qr@^127\.0\.0\.1 - - \[.*?\] "GET / HTTP/1\.1" 200 2@;
}

{
    $log = "";
    $test_req->(POST "http://localhost/foo", { foo => "bar" });
    like $log, qr@^127\.0\.0\.1 - - \[.*?\] "POST /foo HTTP/1\.1" 200 2@;
}

{
    $log = "";
    $test_req->(GET "http://localhost/foo%20bar?baz=baz");
    like $log, qr@GET /foo%20bar\?baz=baz HTTP/1\.1@;
}



# Testing streaming responses

$log = "";
$handler = builder {
    enable "Plack::Middleware::AccessLog::Timed",
        logger => sub { $log .= "@_" };
    
    sub { 
        return sub { 
            my $writer = $_[0]->( [ 200, [ 'Content-Type' => 'text/plain' ] ] );
            $writer->write("OK");
            $writer->close;
        } 
    };
};

$test_req = sub {
    my $req = shift;
    test_psgi app => $handler,
        client => sub {
        my $cb = shift;
        $cb->($req);
    };
};

{
    $test_req->(GET "http://localhost/");
    like $log, qr@^127\.0\.0\.1 - - \[.*?\] "GET / HTTP/1\.1" 200 2@;
}

{
    $log = "";
    $test_req->(POST "http://localhost/foo", { foo => "bar" });
    like $log, qr@^127\.0\.0\.1 - - \[.*?\] "POST /foo HTTP/1\.1" 200 2@;
}

{
    $log = "";
    $test_req->(GET "http://localhost/foo%20bar?baz=baz");
    like $log, qr@GET /foo%20bar\?baz=baz HTTP/1\.1@;
}

# Testing '%D' and '%T'

$log = '';
my $wait_sec = 1;
$handler = builder {
    enable "Plack::Middleware::AccessLog::Timed",
        logger => sub { $log .= "@_" },
        format => '%T %D';
    sub {
        return sub {
            Time::HiRes::sleep $wait_sec;
            $_[0]->( [ 200, [ 'Content-Type' => 'text/plain' ], [ 'OK' ] ] )
        }
    };
};

$test_req = sub {
    my $req = shift;
    test_psgi app => $handler,
        client => sub {
        my $cb = shift;
        $cb->($req);
    };
};


mock_time {
    $wait_sec = 3.5;
    $test_req->(GET "http://localhost/");
    like $log, qr@^\d\.\d+ \d{7}@; # around '3.5 3500000'
} time();

mock_time {
    $wait_sec = 0.3;
    $test_req->(GET "http://localhost/");
    like $log, qr@^\d\.\d+ \d{6}@; # around '0.3 300000'
} time();

done_testing;
