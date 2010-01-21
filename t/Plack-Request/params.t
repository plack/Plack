use strict;
use warnings;
use Test::More;
use Plack::Request;

my $req = Plack::Request->new({ QUERY_STRING => "foo=bar" });
is_deeply $req->parameters, { foo => "bar" };
is $req->param('foo'), "bar";
is_deeply [ $req->param ], [ 'foo' ];

$req = Plack::Request->new({ QUERY_STRING => "foo=bar&foo=baz" });
is_deeply $req->parameters, { foo => "baz" };
is $req->param('foo'), "baz";
is_deeply [ $req->param('foo') ] , [ qw(bar baz) ];
is_deeply [ $req->param ], [ 'foo' ];

$req = Plack::Request->new({ QUERY_STRING => "foo=bar&foo=baz&bar=baz" });
is_deeply $req->parameters, { foo => "baz", bar => "baz" };
is_deeply $req->query_parameters, { foo => "baz", bar => "baz" };
is $req->param('foo'), "baz";
is_deeply [ $req->param('foo') ] , [ qw(bar baz) ];
is_deeply [ sort $req->param ], [ 'bar', 'foo' ];


done_testing;

__END__

=== blank
--- parameters
  key: value
  q: term
--- options
  - qq
--- expected

=== normal
--- parameters
  key: value
  q: term
--- options
  - q
--- expected
  - term

=== array param
--- parameters
  key: value
  q:
    - term
    - search
--- options
  - q
--- expected
  - term
  - search

=== set param
--- parameters
  key: value
  q: term
--- options
  - q
  - search
--- expected
  - search

=== set array param
--- parameters
  key: value
  q: term
--- options
  - q
  - search1
  - search2
--- expected
  - search1
  - search2
