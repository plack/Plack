use strict;
use Plack::Middleware qw( XFramework DebugScreen );
use Plack::Builder;
use Test::More;

my $handler = builder {
    enable Plack::Middleware::XFramework framework => 'Dog';
    enable Plack::Middleware::DebugScreen;
    sub {
        die "Oops";
    };
};

my $res = $handler->(+{});
is $res->[0], 500;

my %hdrs = @{$res->[1]};
is $hdrs{'X-Framework'}, 'Dog';

done_testing;

