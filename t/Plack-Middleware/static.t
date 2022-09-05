use strict;
use warnings;
use Test::More;
use Plack::Middleware::Static;
use Plack::Builder;
use Plack::Util;
use HTTP::Request::Common;
use HTTP::Response;
use Cwd;
use Plack::Test;

my $base = cwd;

Plack::MIME->add_type(".foo" => "text/x-fooo");

my $handler = builder {
    enable "Plack::Middleware::Static",
        path => sub { s!^/share/!!}, root => "share";
    enable "Plack::Middleware::Static",
        path => sub { s!^/more_share/!! if $_[1]->{PATH_INFO} =~ m!^/more_share/!  },
        root => "share";
    enable "Plack::Middleware::Static",
        path => sub { s!^/share-pass/!!}, root => "share", pass_through => 1;
    enable "Plack::Middleware::Static",
        path => qr{\.(t|PL|txt)$}i, root => '.';
    enable "Plack::Middleware::Static",
        path => qr{\.foo$}i, root => '.', 
        content_type => sub { substr Plack::MIME->mime_type($_[0]),0,-1  } ;
    sub {
        [200, ['Content-Type' => 'text/plain', 'Content-Length' => 2], ['ok']]
    };
};

my %test = (
    client => sub {
        my $cb  = shift;

        {
            my $path = "t/test.txt";
            my $res = $cb->(GET "http://localhost/$path");
            is $res->content_type, 'text/plain', 'ok case';
            like $res->content, qr/foo/;
            is -s $path, length($res->content);
            my $content = do { open my $fh, "<", $path; binmode $fh; join '', <$fh> };
            is $content, $res->content;
        }

        {
            my $res = $cb->(GET "http://localhost/..%2f..%2f..%2fetc%2fpasswd.t");
            is $res->code, 403;
        }

        {
            my $res = $cb->(GET "http://localhost/..%2fMakefile.PL");
            is $res->code, 403, 'directory traversal';
        }

        {
            my $res = $cb->(GET "http://localhost/foo/not_found.t");
            is $res->code, 404, 'not found';
            is $res->content, 'not found';
        }

        {
            my $res = $cb->(GET "http://localhost/share/face.jpg");
            is $res->content_type, 'image/jpeg';
        }

        {
            my $res = $cb->(GET "http://localhost/more_share/face.jpg");
            is $res->content_type, 'image/jpeg';
        }

        {
            my $res = $cb->(GET "http://localhost/share-pass/faceX.jpg");
            is $res->code, 200, 'pass through';
            is $res->content, 'ok';
        }

        {
            my $res = $cb->(GET "http://localhost/t/Plack-Middleware/static.txt");
            is $res->content_type, 'text/plain';
            my($ct, $charset) = $res->content_type;
            is $charset, 'charset=utf-8';
        }

        {
            my $res = $cb->(GET "http://localhost/t/Plack-Middleware/static.foo");
            is $res->content_type, 'text/x-foo';
        }
},
    app => $handler,
);

test_psgi %test;

done_testing;
