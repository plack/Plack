use strict;
use warnings;
use Test::More;
use Plack::Request;
use utf8;
use Encode;

{
    my $req = Plack::Request->new({
        QUERY_STRING => "q=%E3%83%A1%E3%82%A4%E3%83%B3%E3%83%9A%E3%83%BC%E3%82%B8",
    });
    is $req->charset, "utf-8";
    is_deeply $req->parameters, { q => "メインページ" };
    is $req->param('q'), "メインページ";
}

{
    my $req = Plack::Request->new({
        QUERY_STRING => "q=%E3%83%A1%E3%82%A4%E3%83%B3%E3%83%9A%E3%83%BC%E3%82%B8",
    });
    $req->default_charset('none');
    is $req->charset, undef;
    ok $req->binary;
    is_deeply $req->parameters, { q => encode_utf8 "メインページ" };
    is $req->param('q'), encode_utf8 "メインページ";
}

{
    my $req = Plack::Request->new({
        QUERY_STRING => "q=%A5%C6%A5%B9%A5%C8",
    });
    $req->default_charset('euc-jp');
    is $req->charset, 'euc-jp';
    is_deeply $req->parameters, { q => "テスト" };
    is $req->param('q'), "テスト";
}

{
    my $body ="q=%A5%C6%A5%B9%A5%C8";
    my $req = Plack::Request->new({
        CONTENT_TYPE   => 'application/x-www-form-urlencoded; charset=euc-jp',
        CONTENT_LENGTH => length $body,
        'psgi.input'   => do { open my $io, "<", \$body; $io },
    });
    is $req->default_charset, 'utf-8';
    is_deeply $req->parameters, { q => "テスト" };
    is $req->param('q'), "テスト";
    is lc $req->charset, 'euc-jp';
}

{
    my $env = {
        QUERY_STRING => "q=%E3%83%A1%E3%82%A4%E3%83%B3%E3%83%9A%E3%83%BC%E3%82%B8",
    };

    my $req = Plack::Request->new($env);
    is $req->charset, "utf-8";
    $req->parameters; # parse and cache

    $req = Plack::Request->new($env, default_charset => 'none');
    is $req->charset, undef;
    ok $req->binary;
    is_deeply $req->parameters, { q => encode_utf8 "メインページ" };
    is $req->param('q'), encode_utf8 "メインページ";
}

done_testing;

