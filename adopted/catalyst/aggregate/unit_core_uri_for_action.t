#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More;

plan tests => 30;

use_ok('TestApp');

my $dispatcher = TestApp->dispatcher;

#
#   Private Action
#
my $private_action = $dispatcher->get_action_by_path(
                       '/class_forward_test_method'
                     );

ok(!defined($dispatcher->uri_for_action($private_action)),
   "Private action returns undef for URI");

#
#   Path Action
#
my $path_action = $dispatcher->get_action_by_path(
                    '/action/testrelative/relative'
                  );

is($dispatcher->uri_for_action($path_action), "/action/relative/relative",
   "Public path action returns correct URI");

ok(!defined($dispatcher->uri_for_action($path_action, [ 'foo' ])),
   "no URI returned for Path action when snippets are given");

#
#   Regex Action
#
my $regex_action = $dispatcher->get_action_by_path(
                     '/action/regexp/one'
                   );

ok(!defined($dispatcher->uri_for_action($regex_action)),
   "Regex action without captures returns undef");

ok(!defined($dispatcher->uri_for_action($regex_action, [ 1, 2, 3 ])),
   "Regex action with too many captures returns undef");

is($dispatcher->uri_for_action($regex_action, [ 'foo', 123 ]),
   "/action/regexp/foo/123",
   "Regex action interpolates captures correctly");

#
#   Index Action
#
my $index_action = $dispatcher->get_action_by_path(
                     '/action/index/index'
                   );

ok(!defined($dispatcher->uri_for_action($index_action, [ 'foo' ])),
   "no URI returned for index action when snippets are given");

is($dispatcher->uri_for_action($index_action),
   "/action/index",
   "index action returns correct path");

#
#   Chained Action
#
my $chained_action = $dispatcher->get_action_by_path(
                       '/action/chained/endpoint',
                     );

ok(!defined($dispatcher->uri_for_action($chained_action)),
   "Chained action without captures returns undef");

ok(!defined($dispatcher->uri_for_action($chained_action, [ 1, 2 ])),
   "Chained action with too many captures returns undef");

is($dispatcher->uri_for_action($chained_action, [ 1 ]),
   "/chained/foo/1/end",
   "Chained action with correct captures returns correct path");

#
#   Tests with Context
#
my $request = Catalyst::Request->new( {
                base => URI->new('http://127.0.0.1/foo')
              } );

my $context = TestApp->new( {
                request => $request,
                namespace => 'yada',
              } );

is($context->uri_for($context->controller('Action')),
   "http://127.0.0.1/foo/yada/action/",
   "uri_for a controller");

is($context->uri_for($path_action),
   "http://127.0.0.1/foo/action/relative/relative",
   "uri_for correct for path action");

is($context->uri_for($path_action, qw/one two/, { q => 1 }),
   "http://127.0.0.1/foo/action/relative/relative/one/two?q=1",
   "uri_for correct for path action with args and query");

ok(!defined($context->uri_for($path_action, [ 'blah' ])),
   "no URI returned by uri_for for Path action with snippets");

is($context->uri_for($regex_action, [ 'foo', 123 ], qw/bar baz/, { q => 1 }),
   "http://127.0.0.1/foo/action/regexp/foo/123/bar/baz?q=1",
   "uri_for correct for regex with captures, args and query");

is($context->uri_for($chained_action, [ 1 ], 2, { q => 1 }),
   "http://127.0.0.1/foo/chained/foo/1/end/2?q=1",
   "uri_for correct for chained with captures, args and query");

#
#   More Chained with Context Tests
#
{
    is( $context->uri_for_action( '/action/chained/endpoint2', [1,2], (3,4), { x => 5 } ),
        'http://127.0.0.1/foo/chained/foo2/1/2/end2/3/4?x=5',
        'uri_for_action correct for chained with multiple captures and args' );

    is( $context->uri_for_action( '/action/chained/three_end', [1,2,3], (4,5,6) ),
        'http://127.0.0.1/foo/chained/one/1/two/2/3/three/4/5/6',
        'uri_for_action correct for chained with multiple capturing actions' );

    my $action_needs_two = '/action/chained/endpoint2';
    
    ok( ! defined( $context->uri_for_action($action_needs_two, [1],     (2,3)) ),
        'uri_for_action returns undef for not enough captures' );
        
    is( $context->uri_for_action($action_needs_two,            [1,2],   (2,3)),
        'http://127.0.0.1/foo/chained/foo2/1/2/end2/2/3',
        'uri_for_action returns correct uri for correct captures' );
        
    ok( ! defined( $context->uri_for_action($action_needs_two, [1,2,3], (2,3)) ),
        'uri_for_action returns undef for too many captures' );
    
    is( $context->uri_for_action($action_needs_two, [1,2],   (3)),
        'http://127.0.0.1/foo/chained/foo2/1/2/end2/3',
        'uri_for_action returns uri with lesser args than specified on action' );

    is( $context->uri_for_action($action_needs_two, [1,2],   (3,4,5)),
        'http://127.0.0.1/foo/chained/foo2/1/2/end2/3/4/5',
        'uri_for_action returns uri with more args than specified on action' );

    is( $context->uri_for_action($action_needs_two, [1,''], (3,4)),
        'http://127.0.0.1/foo/chained/foo2/1//end2/3/4',
        'uri_for_action returns uri with empty capture on undef capture' );

    is( $context->uri_for_action($action_needs_two, [1,2], ('',3)),
        'http://127.0.0.1/foo/chained/foo2/1/2/end2//3',
        'uri_for_action returns uri with empty arg on undef argument' );

    is( $context->uri_for_action($action_needs_two, [1,2], (3,'')),
        'http://127.0.0.1/foo/chained/foo2/1/2/end2/3/',
        'uri_for_action returns uri with empty arg on undef last argument' );

    my $complex_chained = '/action/chained/empty_chain_f';
    is( $context->uri_for_action( $complex_chained, [23], (13), {q => 3} ),
        'http://127.0.0.1/foo/chained/empty/23/13?q=3',
        'uri_for_action returns correct uri for chain with many empty path parts' );

    eval { $context->uri_for_action( '/does/not/exist' ) };
    like $@, qr{^Can't find action for path '/does/not/exist'},
        'uri_for_action croaks on nonexistent path';

}

