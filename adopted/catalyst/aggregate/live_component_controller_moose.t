use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More tests => 12;
use Catalyst::Test 'TestApp';

{
    my $response = request('http://localhost/moose/get_attribute');
    ok($response->is_success);
    is($response->content, '42', 'attribute default values get set correctly');
}

{
    my $response = request('http://localhost/moose/methodmodifiers/get_attribute');       
    ok($response->is_success);
    is($response->content, '42', 'parent controller method called');
    is($response->header('X-Catalyst-Test-After'), 'after called', 'after works as expected');
}

{
    my $response = request('http://localhost/moose/with_local_modifier');
    ok($response->is_success);
    is($response->content, '42', 'attribute default values get set correctly');
    is($response->header('X-Catalyst-Test-Before'), 'before called', 'before works as expected');
}
{
    my $response = request('http://localhost/moose/methodmodifiers/with_local_modifier');
    ok($response->is_success);
    is($response->content, '42', 'attribute default values get set correctly');
    is($response->header('X-Catalyst-Test-After'), 'after called', 'after works as expected');
    is($response->header('X-Catalyst-Test-Before'), 'before called', 'before works as expected');
}

