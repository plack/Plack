#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use 5.010000;
use autodie;

use Plack::Request;
use Plack::BodyParser::UrlEncoded;
use Plack::BodyParser::JSON;
use Plack::BodyParser::MultiPart;
use Plack::BodyParser::OctetStream;

use Benchmark ':all';

my $content = 'xxx=hogehoge&yyy=aaaaaaaaaaaaaaaaaaaaa';

my $body_parser = sub {
    open my $input, '<', \$content;
    my $req = Plack::Request->new(
        +{
            'psgi.input' => $input,
            CONTENT_LENGTH => length($content),
            CONTENT_TYPE => 'application/x-www-form-urlencoded',
        },
        parse_request_body => \&parse_request_body,
    );
    $req->body_parameters;
};
my $orig = sub {
    open my $input, '<', \$content;
    my $req = Plack::Request->new(
        +{
            'psgi.input' => $input,
            CONTENT_LENGTH => length($content),
            CONTENT_TYPE => 'application/x-www-form-urlencoded',
        },
    );
    $req->body_parameters;
};
use Data::Dumper; warn Dumper($orig->());
use Data::Dumper; warn Dumper($body_parser->());

cmpthese(
    -1, {
        orig => $orig,
        body_parser => $body_parser,
    },
);

sub parse_request_body {
    my $req = shift;
    my $content_type = $req->content_type;

    my $parser =
        $content_type =~ m{\Aapplication/json}
            ? Plack::BodyParser::JSON->new()
        : $content_type =~ m{\Aapplication/x-www-form-urlencoded}
            ? Plack::BodyParser::UrlEncoded->new()
        : $content_type =~ m{\Amultipart/form-data}
            ? Plack::BodyParser::MultiPart->new($req->env)
            : Plack::BodyParser::OctetStream->new()
    ;
    Plack::BodyParser->parse($req->env, $parser);
}

