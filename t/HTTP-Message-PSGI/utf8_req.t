use Test::More;
use Encode;
use HTTP::Request;
use HTTP::Message::PSGI;

my @paths = (
    'П', '%D0%9F',
    decode_utf8('П'), '%D0%9F',
    'À', '%C3%80',
    decode_utf8('À'), '%C3%80',
);

while (my($raw, $encoded) = splice @paths, 0, 2) {
    my $req = HTTP::Request->new(GET => "http://localhost/" . $raw);
    my $env = $req->to_psgi;
    is $env->{REQUEST_URI}, "/$encoded";
    is $env->{PATH_INFO}, URI::Escape::uri_unescape("/$encoded");
    ok !utf8::is_utf8 $env->{PATH_INFO};
    ok !utf8::is_utf8 $env->{HTTP_HOST};
}

done_testing;

