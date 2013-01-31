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

done_testing;
