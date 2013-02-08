use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;
use POSIX;

my $log;

my $test = sub {
    my $format = shift;
    return sub {
        my $req = shift;
        my $app = builder {
            enable "Plack::Middleware::AccessLog",
                logger => sub { $log = "@_" }, format => $format;
            sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ 'OK' ] ] };
        };
        test_psgi $app, sub { $_[0]->($req) };
    };
};

{
    my $req = GET "http://example.com/", (
        'User-Agent' => 'Plack::Test',
        'Referer' => 'http://example.com/referer'
    );
    $test->('ltsv')->($req);
    chomp $log;
    my %record = map { split ':', $_, 2 } split "\t", $log;

    my $month_year = POSIX::strftime('%m %y', localtime);
    is $record{host}, '127.0.0.1';
    is $record{user}, '-';
    is $record{req}, 'GET / HTTP/1.1';
    is $record{status}, 200;
    is $record{size}, length 'OK';
    is $record{referer}, 'http://example.com/referer';
    is $record{ua}, 'Plack::Test';
}

done_testing;
