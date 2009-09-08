use strict;
use warnings;
use Test::More;

BEGIN {
    unless (eval 'use CatalystX::LeakChecker 0.03; 1') {
        plan skip_all => 'CatalystX::LeakChecker 0.03 required for this test';
    }

    plan tests => 4;
}

use FindBin;
use lib "$FindBin::Bin/lib";

use Catalyst::Test 'TestApp';

{
    my ($resp, $ctx) = ctx_request('/contextclosure/normal_closure');
    ok($resp->is_success);
    is($ctx->count_leaks, 1);
}

{
    my ($resp, $ctx) = ctx_request('/contextclosure/context_closure');
    ok($resp->is_success);
    is($ctx->count_leaks, 0);
}
