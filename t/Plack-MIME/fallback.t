use Test::More;
use Test::Requires qw(MIME::Types);
use Plack::MIME;
use MIME::Types 'by_suffix';

is( Plack::MIME->mime_type(".vcd"), undef );

Plack::MIME->set_fallback(sub { (by_suffix $_[0])[0] });
is( Plack::MIME->mime_type(".vcd"), "application/x-cdlink" );

done_testing;
