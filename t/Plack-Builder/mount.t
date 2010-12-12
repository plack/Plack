use strict;
use Test::More;

my $builder = sub {
    use Plack::Builder;

    builder {
        mount "/foo" => sub { };
        sub { warn @_ };
    };
};

my @warn;
{
    local $SIG{__WARN__} = sub { push @warn, @_ };
    my $app = $builder->();
    ok $app;
}

like $warn[0], qr/mount/;

done_testing;
