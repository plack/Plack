#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

our $iters;

BEGIN { $iters = $ENV{CAT_BENCH_ITERS} || 1; }

use Test::More tests => 60 * $iters;
use Catalyst::Test 'TestApp';

if ( $ENV{CAT_BENCHMARK} ) {
    require Benchmark;
    Benchmark::timethis( $iters, \&run_tests );
}
else {
    for ( 1 .. $iters ) {
        run_tests();
    }
}

sub run_tests {
    {
        # Test visit to global private action
        ok( my $response = request('http://localhost/action/visit/global'),
            'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content_type, 'text/plain', 'Response Content-Type' );
        is( $response->header('X-Catalyst-Action'),
            'action/visit/global', 'Main Class Action' );
    }

    {
        my @expected = qw[
          TestApp::Controller::Action::Visit->one
          TestApp::Controller::Action::Visit->two
          TestApp::Controller::Action::Visit->three
          TestApp::Controller::Action::Visit->four
          TestApp::Controller::Action::Visit->five
          TestApp::View::Dump::Request->process
          TestApp->end
          TestApp->end
          TestApp->end
          TestApp->end
          TestApp->end
        ];

        @expected = map { /Action/ ? (_begin($_), $_) : ($_) } @expected;
        my $expected = join( ", ", @expected );

        # Test visit to chain of actions.
        ok( my $response = request('http://localhost/action/visit/one'),
            'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content_type, 'text/plain', 'Response Content-Type' );
        is( $response->header('X-Catalyst-Action'),
            'action/visit/one', 'Test Action' );
        is(
            $response->header('X-Test-Class'),
            'TestApp::Controller::Action::Visit',
            'Test Class'
        );
        is( $response->header('X-Catalyst-Executed'),
            $expected, 'Executed actions' );
        like(
            $response->content,
            qr/^bless\( .* 'Catalyst::Request' \)$/s,
            'Content is a serialized Catalyst::Request'
        );
    }
    {
        my @expected = qw[
          TestApp::Controller::Action::Visit->visit_die
          TestApp::Controller::Action::Visit->args
          TestApp->end
          TestApp->end
        ];

        @expected = map { /Action/ ? (_begin($_), $_) : ($_) } @expected;
        my $expected = join( ", ", @expected );

        ok( my $response = request('http://localhost/action/visit/visit_die'),
            'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content_type, 'text/plain', 'Response Content-Type' );
        is( $response->header('X-Catalyst-Action'),
            'action/visit/visit_die', 'Test Action'
        );
        is(
            $response->header('X-Test-Class'),
            'TestApp::Controller::Action::Visit',
            'Test Class'
        );
        is( $response->header('X-Catalyst-Executed'),
            $expected, 'Executed actions' );
        is( $response->content, "visit() doesn't die", "Visit does not die" );
    }
    {
        ok(
            my $response = request('http://localhost/action/visit/model'),
            'Request with args'
        );
        is( $response->content,
            q[FATAL ERROR: Couldn't visit("Model::Foo"): Action cannot _DISPATCH. Did you try to visit() a non-controller action?]
        );
    }
    {
        ok(
            my $response = request('http://localhost/action/visit/view'),
            'Request with args'
        );
        is( $response->content,
            q[FATAL ERROR: Couldn't visit("View::Dump"): Action cannot _DISPATCH. Did you try to visit() a non-controller action?]
        );
    }
    {
        ok(
            my $response =
              request('http://localhost/action/visit/with_args/old'),
            'Request with args'
        );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content, 'old', 'visit() with args (old)' );
    }

    {
        ok(
            my $response = request(
                'http://localhost/action/visit/with_method_and_args/new'),
            'Request with args and method'
        );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content, 'new', 'visit() with args (new)' );
    }

    # test visit with embedded args
    {
        ok(
            my $response =
              request('http://localhost/action/visit/args_embed_relative'),
            'Request'
        );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content, 'ok', 'visit() with args_embed_relative' );
    }

    {
        ok(
            my $response =
              request('http://localhost/action/visit/args_embed_absolute'),
            'Request'
        );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content, 'ok', 'visit() with args_embed_absolute' );
    }
    {
        my @expected = qw[
          TestApp::Controller::Action::TestRelative->relative_visit
          TestApp::Controller::Action::Visit->one
          TestApp::Controller::Action::Visit->two
          TestApp::Controller::Action::Visit->three
          TestApp::Controller::Action::Visit->four
          TestApp::Controller::Action::Visit->five
          TestApp::View::Dump::Request->process
          TestApp->end
          TestApp->end
          TestApp->end
          TestApp->end
          TestApp->end
          TestApp->end
        ];

        @expected = map { /Action/ ? (_begin($_), $_) : ($_) } @expected;
        my $expected = join( ", ", @expected );

        # Test visit to chain of actions.
        ok( my $response = request('http://localhost/action/relative/relative_visit'),
            'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content_type, 'text/plain', 'Response Content-Type' );
        is( $response->header('X-Catalyst-Action'),
            'action/relative/relative_visit', 'Test Action' );
        is(
            $response->header('X-Test-Class'),
            'TestApp::Controller::Action::Visit',
            'Test Class'
        );
        is( $response->header('X-Catalyst-Executed'),
            $expected, 'Executed actions' );
        like(
            $response->content,
            qr/^bless\( .* 'Catalyst::Request' \)$/s,
            'Content is a serialized Catalyst::Request'
        );
    }
    {
        my @expected = qw[
          TestApp::Controller::Action::TestRelative->relative_visit_two
          TestApp::Controller::Action::Visit->one
          TestApp::Controller::Action::Visit->two
          TestApp::Controller::Action::Visit->three
          TestApp::Controller::Action::Visit->four
          TestApp::Controller::Action::Visit->five
          TestApp::View::Dump::Request->process
          TestApp->end
          TestApp->end
          TestApp->end
          TestApp->end
          TestApp->end
          TestApp->end
        ];

        @expected = map { /Action/ ? (_begin($_), $_) : ($_) } @expected;
        my $expected = join( ", ", @expected );

        # Test visit to chain of actions.
        ok(
            my $response =
              request('http://localhost/action/relative/relative_visit_two'),
            'Request'
        );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content_type, 'text/plain', 'Response Content-Type' );
        is(
            $response->header('X-Catalyst-Action'),
            'action/relative/relative_visit_two',
            'Test Action'
        );
        is(
            $response->header('X-Test-Class'),
            'TestApp::Controller::Action::Visit',
            'Test Class'
        );
        is( $response->header('X-Catalyst-Executed'),
            $expected, 'Executed actions' );
        like(
            $response->content,
            qr/^bless\( .* 'Catalyst::Request' \)$/s,
            'Content is a serialized Catalyst::Request'
        );
    }

    # test class visit -- MUST FAIL!
    {
        ok(
            my $response = request(
                'http://localhost/action/visit/class_visit_test_action'),
            'Request'
        );
        ok( !$response->is_success, 'Response Fails' );
        is( $response->content,
            q{FATAL ERROR: Couldn't visit("TestApp"): Action has no namespace: cannot visit() to a plain method or component, must be an :Action of some sort.},
            "Cannot visit app namespace"
        );
    }

    {
        my @expected = qw[
          TestApp::Controller::Action::Visit->begin
          TestApp::Controller::Action::Visit->visit_chained
          TestApp::Controller::Action::Chained->begin
          TestApp::Controller::Action::Chained->foo
          TestApp::Controller::Action::Chained::Foo->spoon
          TestApp::Controller::Action::Chained->end
          TestApp->end
        ];

        my $expected = join( ", ", @expected );

        for my $i ( 1..3 ) {
            ok( my $response = request("http://localhost/action/visit/visit_chained/$i/becomescapture/arg1/arg2"),
                "visit to chained + subcontroller endpoint for $i" );
            is( $response->header('X-Catalyst-Executed'),
                $expected, "Executed actions for $i" );
            is( $response->content, "arg1, arg2; becomescapture",
                "Content OK for $i" );
        }
    }

}



sub _begin {
    local $_ = shift;
    s/->(.*)$/->begin/;
    return $_;
}

