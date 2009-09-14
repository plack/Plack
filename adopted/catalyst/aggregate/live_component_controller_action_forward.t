#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

our $iters;

BEGIN { $iters = $ENV{CAT_BENCH_ITERS} || 1; }

use Test::More tests => 53 * $iters;
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
        my @expected = qw[
          TestApp::Controller::Action::Forward->begin
          TestApp::Controller::Action::Forward->one
          TestApp::Controller::Action::Forward->two
          TestApp::Controller::Action::Forward->three
          TestApp::Controller::Action::Forward->four
          TestApp::Controller::Action::Forward->five
          TestApp::View::Dump::Request->process
          TestApp->end
        ];

        my $expected = join( ", ", @expected );

        # Test forward to global private action
        ok( my $response = request('http://localhost/action/forward/global'),
            'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content_type, 'text/plain', 'Response Content-Type' );
        is( $response->header('X-Catalyst-Action'),
            'action/forward/global', 'Main Class Action' );

        # Test forward to chain of actions.
        ok( $response = request('http://localhost/action/forward/one'),
            'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content_type, 'text/plain', 'Response Content-Type' );
        is( $response->header('X-Catalyst-Action'),
            'action/forward/one', 'Test Action' );
        is(
            $response->header('X-Test-Class'),
            'TestApp::Controller::Action::Forward',
            'Test Class'
        );
        is( $response->header('X-Catalyst-Executed'),
            $expected, 'Executed actions' );
        like(
            $response->content,
            qr/bless\( .* 'Catalyst::Request' \)/s,
            'Content is a serialized Catalyst::Request'
        );
    }

    {
        my @expected = qw[
          TestApp::Controller::Action::Forward->begin
          TestApp::Controller::Action::Forward->jojo
          TestApp::Controller::Action::Forward->one
          TestApp::Controller::Action::Forward->two
          TestApp::Controller::Action::Forward->three
          TestApp::Controller::Action::Forward->four
          TestApp::Controller::Action::Forward->five
          TestApp::View::Dump::Request->process
          TestApp::Controller::Action::Forward->three
          TestApp::Controller::Action::Forward->four
          TestApp::Controller::Action::Forward->five
          TestApp::View::Dump::Request->process
          TestApp->end
        ];

        my $expected = join( ", ", @expected );

        ok( my $response = request('http://localhost/action/forward/jojo'),
            'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content_type, 'text/plain', 'Response Content-Type' );
        is( $response->header('X-Catalyst-Action'),
            'action/forward/jojo', 'Test Action' );
        is(
            $response->header('X-Test-Class'),
            'TestApp::Controller::Action::Forward',
            'Test Class'
        );
        is( $response->header('X-Catalyst-Executed'),
            $expected, 'Executed actions' );
        like(
            $response->content,
            qr/bless\( .* 'Catalyst::Request' \)/s,
            'Content is a serialized Catalyst::Request'
        );
    }

    {
        ok(
            my $response =
              request('http://localhost/action/forward/with_args/old'),
            'Request with args'
        );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content, 'old' );
    }

    {
        ok(
            my $response = request(
                'http://localhost/action/forward/with_method_and_args/old'),
            'Request with args and method'
        );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content, 'old' );
    }

    # test forward with embedded args
    {
        ok(
            my $response =
              request('http://localhost/action/forward/args_embed_relative'),
            'Request'
        );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content, 'ok' );
    }

    {
        ok(
            my $response =
              request('http://localhost/action/forward/args_embed_absolute'),
            'Request'
        );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content, 'ok' );
    }
    {
        my @expected = qw[
          TestApp::Controller::Action::TestRelative->begin
          TestApp::Controller::Action::TestRelative->relative
          TestApp::Controller::Action::Forward->one
          TestApp::Controller::Action::Forward->two
          TestApp::Controller::Action::Forward->three
          TestApp::Controller::Action::Forward->four
          TestApp::Controller::Action::Forward->five
          TestApp::View::Dump::Request->process
          TestApp->end
        ];

        my $expected = join( ", ", @expected );

        # Test forward to chain of actions.
        ok( my $response = request('http://localhost/action/relative/relative'),
            'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content_type, 'text/plain', 'Response Content-Type' );
        is( $response->header('X-Catalyst-Action'),
            'action/relative/relative', 'Test Action' );
        is(
            $response->header('X-Test-Class'),
            'TestApp::Controller::Action::TestRelative',
            'Test Class'
        );
        is( $response->header('X-Catalyst-Executed'),
            $expected, 'Executed actions' );
        like(
            $response->content,
            qr/bless\( .* 'Catalyst::Request' \)/s,
            'Content is a serialized Catalyst::Request'
        );
    }
    {
        my @expected = qw[
          TestApp::Controller::Action::TestRelative->begin
          TestApp::Controller::Action::TestRelative->relative_two
          TestApp::Controller::Action::Forward->one
          TestApp::Controller::Action::Forward->two
          TestApp::Controller::Action::Forward->three
          TestApp::Controller::Action::Forward->four
          TestApp::Controller::Action::Forward->five
          TestApp::View::Dump::Request->process
          TestApp->end
        ];

        my $expected = join( ", ", @expected );

        # Test forward to chain of actions.
        ok(
            my $response =
              request('http://localhost/action/relative/relative_two'),
            'Request'
        );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content_type, 'text/plain', 'Response Content-Type' );
        is(
            $response->header('X-Catalyst-Action'),
            'action/relative/relative_two',
            'Test Action'
        );
        is(
            $response->header('X-Test-Class'),
            'TestApp::Controller::Action::TestRelative',
            'Test Class'
        );
        is( $response->header('X-Catalyst-Executed'),
            $expected, 'Executed actions' );
        like(
            $response->content,
            qr/bless\( .* 'Catalyst::Request' \)/s,
            'Content is a serialized Catalyst::Request'
        );
    }

    # test class forwards
    {
        ok(
            my $response = request(
                'http://localhost/action/forward/class_forward_test_action'),
            'Request'
        );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->header('X-Class-Forward-Test-Method'), 1,
            'Test Method' );
    }

    # test uri_for re r7385
    {
        ok( my $response = request(
            'http://localhost/action/forward/forward_to_uri_check'),
            'forward_to_uri_check request');

        ok( $response->is_success, 'forward_to_uri_check successful');
        is( $response->content, '/action/forward/foo/bar',
             'forward_to_uri_check correct namespace');
    }

    # test forwarding to Catalyst::Action objects
    {
        ok( my $response = request(
            'http://localhost/action/forward/to_action_object'),
            'forward/to_action_object request');

        ok( $response->is_success, 'forward/to_action_object successful');
        is( $response->content, 'mtfnpy',
             'forward/to_action_object forwards correctly');
    }
}
