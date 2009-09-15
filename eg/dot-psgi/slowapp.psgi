# emulate a slow web app that does DB query etc.
use Time::HiRes qw(sleep);
my $handler = sub {
    sleep 0.1;
    return [ 200, [ "Content-Type" => "text/plain", "Content-Length" => 11 ], [ "Hello World" ] ];
};
