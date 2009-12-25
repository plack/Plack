use Plack::MIME;
use Test::More;

sub x($) { Plack::MIME->mime_type($_[0]) }

is x ".gif", "image/gif";
is x "foo.png", "image/png";
is x "foo.GIF", "image/gif";
is x "foo.bar", undef;

done_testing;
