use strict;
use warnings;
use utf8;
use Test::More 0.96;
use Hash::MultiValue;
use Plack::BodyParser::UrlEncoded;

my $parser = Plack::BodyParser::UrlEncoded->new();
$parser->add('oo=xx%20yy');
my ($params, $uploads) = $parser->finalize();
is_deeply $params,  Hash::MultiValue->new('oo' => 'xx yy');
is_deeply $uploads, Hash::MultiValue->new();

done_testing;

