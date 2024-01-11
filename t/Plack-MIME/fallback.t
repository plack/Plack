use Test::More;
use Test::Requires qw(MIME::Types);
use Plack::MIME;
use MIME::Types 'by_suffix';

is( Plack::MIME->mime_type(".ncm"), undef );

Plack::MIME->set_fallback(sub { (by_suffix $_[0])[0] });
is( Plack::MIME->mime_type(".ncm"), "application/vnd.nokia.configuration-message" );

done_testing;
