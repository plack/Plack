use strict;
use warnings;
use Test::Base;

use t::Utils;

plan tests => 4*blocks;

filters {
    parameters => [qw/yaml/],
    options    => [qw/yaml/],
    expected   => [qw/yaml/],
};

run {
    my $block = shift;
    my $req = req(env => {} );
    $req->parameters($block->parameters);
    is_deeply $req->params, $block->parameters;
    is scalar($req->param), scalar(keys %{  $block->parameters });

    my @options = $block->options;
    @options = @{ $block->options } if ref $block->options;

    my $ret = $req->param(@options);
    if (@options > 1) {
        is_deeply $ret, $block->expected;
        return ok 1 
    }
    my $expected = $block->expected ? $block->expected->[0] : undef;
    is $ret, $expected;

    my @ret = $req->param(@options);
    return ok 1 unless @ret && $block->expected;
    is_deeply \@ret, $block->expected;
}

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
