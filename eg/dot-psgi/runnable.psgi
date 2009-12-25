#!/usr/bin/perl
unless (caller) {
    require Plack::Runner;
    Plack::Runner->run(@ARGV, $0);
}

my $handler = sub {
    return [ 200, [ "Content-Type" => "text/plain", "Content-Length" => 11 ], [ "Hello World" ] ];
};
