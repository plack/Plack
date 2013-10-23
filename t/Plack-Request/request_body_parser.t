use strict;
use warnings;
use utf8;
use Test::More;

use Plack::Request;
use Plack::BodyParser::UrlEncoded;
use Plack::BodyParser::JSON;
use Plack::BodyParser::MultiPart;
use Plack::BodyParser::OctetStream;

subtest 'JSON' => sub {
    is_deeply make_request('application/json', '{"hoge":"fuga"}')->parameters()->as_hashref_multi, {
        hoge => ['fuga'],
    };
};

subtest 'UrlEncoded' => sub {
    is_deeply make_request('application/x-www-form-urlencoded', 'xxx=yyy')->parameters()->as_hashref_multi, {
        xxx => ['yyy'],
    };
};

subtest 'MultiPart' => sub {
    my $content = <<'...';
--BOUNDARY
Content-Disposition: form-data; name="xxx"
Content-Type: text/plain

yyy
--BOUNDARY
Content-Disposition: form-data; name="yappo"; filename="osawa.txt"
Content-Type: text/plain

SHOGUN
--BOUNDARY--
...
    $content =~ s/\r\n/\n/g;
    $content =~ s/\n/\r\n/g;

    my $req = make_request('multipart/form-data; boundary=BOUNDARY', $content);
    is_deeply $req->parameters()->as_hashref_multi, {
        xxx => ['yyy'],
    };

    is slurp($req->upload('yappo')), 'SHOGUN';
    is $req->upload('yappo')->filename, 'osawa.txt';
};

subtest 'OctetStream' => sub {
    my $content = 'hogehoge';
    my $req = make_request('application/octet-stream', $content);
    is $req->content, 'hogehoge';
    is 0+($req->parameters->keys), 0;
    is 0+($req->uploads->keys), 0;
};

done_testing;

sub make_request {
    my ($content_type, $content) = @_;

    open my $input, '<', \$content;
    my $req = Plack::Request->new(
        +{
            'psgi.input'   => $input,
            CONTENT_TYPE   => $content_type,
            CONTENT_LENGTH => length($content),
        },
        parse_request_body => \&parse_request_body,
    );
    return $req;
}

sub parse_request_body {
    my $req = shift;

    my $parser =
        $req->content_type =~ m{\Aapplication/json}
            ? Plack::BodyParser::JSON->new()
        : $req->content_type =~ m{\Aapplication/x-www-form-urlencoded}
            ? Plack::BodyParser::UrlEncoded->new()
        : $req->content_type =~ m{\Amultipart/form-data}
            ? Plack::BodyParser::MultiPart->new($req->env)
            : Plack::BodyParser::OctetStream->new()
    ;
    Plack::BodyParser->parse($req->env, $parser);
}

sub slurp {
    my $up = shift;
    open my $fh, "<", $up->path or die "$!";
    scalar do { local $/; <$fh> };
}

