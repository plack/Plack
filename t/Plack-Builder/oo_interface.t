use strict;
use warnings;
use Test::More;
use Plack::Builder;
use HTTP::Request::Common;
use Plack::Test;

my $app = sub {
    [200, ['Content-Type', 'text/plain'], ['ok']]
};

sub test_app {
    my $app = shift;
    is ref($app), 'CODE';
    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->(GET "/app/foo/bar");
        ok $res->header('X-Runtime');
        is $res->header('X-Framework'), 'Plack::Builder';
        is $res->content, "ok";
    };
}

{
    # old (doucmented :/) interface - backward compatibility
    my $builder = Plack::Builder->new;
    $builder->add_middleware('Runtime');
    $builder->add_middleware('XFramework', framework => 'Plack::Builder');
    my $new_app = $builder->mount('/app/foo/bar' => $app);
    test_app $builder->to_app($new_app);
}

{
    my $builder = Plack::Builder->new;
    $builder->add_middleware('Runtime');
    $builder->add_middleware('XFramework', framework => 'Plack::Builder');
    $builder->mount('/app/foo/bar' => $app);
    test_app $builder->to_app;
}

{
    my $builder = Plack::Builder->new;
    $builder->add_middleware_if(sub { $_[0]->{HTTP_HOST} eq 'localhost' }, 'Runtime');
    $builder->add_middleware('XFramework', framework => 'Plack::Builder');
    $builder->mount('/app/foo/bar' => $app);
    test_app $builder->to_app;
}

{
    my $builder = Plack::Builder->new;
    $builder->add_middleware('Runtime');
    eval { $builder->to_app };
    like $@, qr/called without mount/, $@;
}

{
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, @_ };
    my $builder = Plack::Builder->new;
    $builder->mount('/bar' => sub { [ 200, [], [''] ] });
    $builder->wrap($app);
    like $warn[0], qr/mappings to be ignored/;
}

{
    local $ENV{PLACK_ENV} = 'development';
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, @_ };
    my $builder = Plack::Builder->new;
    $builder->add_middleware('Runtime');
    $builder->add_middleware('XFramework', framework => 'Plack::Builder');
    $builder->mount('/app/foo/bar' => $app);
    test_app $builder->to_app;
    is_deeply(\@warn, [], "no warnings");
}

done_testing;
