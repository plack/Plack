# emulate a slow web app that does DB query etc.
use Time::HiRes;

sub _sleep {
    # If it's running in Coro, you can use Coro's co-operative multi
    # tasking to do time-consuming task by yeilding to other threads:
    # we use Coro::Timer::sleep to demonstrate that:
    if ($INC{"Coro.pm"}) {
        require Coro::Timer;
        Coro::Timer::sleep( $_[0] );
    } else {
        Time::HiRes::sleep( $_[0] );
    }
}

my $handler = sub {
    _sleep 0.1; # emulate the DB/IO task that takes 0.1 second
    return [ 200, [ "Content-Type" => "text/plain", "Content-Length" => 11 ], [ "Hello World" ] ];
};
