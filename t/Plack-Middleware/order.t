use strict;
use Plack::Builder;
use Test::More;

my $handler = builder {
    enable "Plack::Middleware::XFramework", framework => 'Dog';
    enable "Plack::Middleware::StackTrace";
    sub {
        die "Oops";
    };
};

open my $io, ">", \my $err;
my $res = $handler->({ 'psgi.errors' => $io });
is $res->[0], 500;

my %hdrs = @{$res->[1]};
is $hdrs{'X-Framework'}, 'Dog';

done_testing;

