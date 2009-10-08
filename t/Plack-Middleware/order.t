use strict;
use Test::Requires qw( CGI::ExceptionManager );
use Plack::Builder;
use Test::More;

my $handler = builder {
    add "Plack::Middleware::XFramework", framework => 'Dog';
    add "Plack::Middleware::StackTrace";
    sub {
        die "Oops";
    };
};

my $res = $handler->(+{});
is $res->[0], 500;

my %hdrs = @{$res->[1]};
is $hdrs{'X-Framework'}, 'Dog';

done_testing;

