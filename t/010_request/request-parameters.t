use strict;
use warnings;
use Test::More tests => 2;

use t::Utils;

do {
    my $req = req(env => {CONTENT_LENGTH => 0, 'psgi.input' => *STDIN, CONTENT_TYPE => 'text/plain'});
    $req->body_parameters(foo => 'bar');
    $req->body_parameters(hoge => 'one');
    $req->query_parameters({bar => 'baz', hoge => 'two'});
    is_deeply $req->parameters(), {foo => 'bar', 'bar' => 'baz', hoge => [qw/ two one /]};
};

do {
    my $req = req(env => {CONTENT_LENGTH => 0, 'psgi.input' => *STDIN, CONTENT_TYPE => 'text/plain'});
    $req->body_parameters(foo => 'bar');
    $req->body_parameters(hoge => 'one');
    $req->query_parameters({bar => ['baz', 'bar'], hoge => 'two'});
    is_deeply $req->parameters(), {foo => 'bar', 'bar' => ['baz', 'bar'], hoge => [qw/ two one /]};
};

