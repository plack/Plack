use strict;
use warnings;
use Test::More;

use Hash::MultiValue;
use Plack::BodyParser::JSON;

my $parser = Plack::BodyParser::JSON->new();
$parser->add('{');
$parser->add('"hoge":["fuga","hige"],');
$parser->add('"\u306b\u307b\u3093\u3054":"\u65e5\u672c\u8a9e",');
$parser->add('"moge":"muga"');
$parser->add('}');

my ($params, $uploads) = $parser->finalize();
is_deeply $params->as_hashref_multi,
  +{
    'hoge'     => [ 'fuga', 'hige' ],
    'moge'     => ['muga'],
    'にほんご' => ['日本語'],
  };
is_deeply [$uploads->keys], [];

done_testing;

