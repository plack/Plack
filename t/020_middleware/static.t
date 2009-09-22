use strict;
use warnings;
use Test::More;
use Test::Requires qw( Path::Class );
use Plack::Middleware::Static;
use Plack::Builder;
use Plack::Util;
use HTTP::Response;
use Path::Class;

chdir 't'; # XXX

my $handler = builder {
    enable Plack::Middleware::Static
        'rules' => [{
            path => qr{\.(t|PL|jpg)$}i,
            root => '.',
        }],
        mime_types => {
            t => 'text/x-perl-test',
        }
    ;
    sub {
        [200, ['Content-Type' => 'text/plain', 'Content-Length' => 2], ['ok']]
    };
};

&main;exit;

# -------------------------------------------------------------------------

sub main {
    do {
        my $res = psgi2hres($handler->(+{PATH_INFO => '/01_response.t'}));
        is $res->content_type, 'text/x-perl-test', 'ok case';
        like $res->content, qr/use Test::More/;
        is file('01_response.t')->stat->size, length($res->content);
        is file('01_response.t')->slurp,$res->content;
    };

    do {
        my $res = psgi2hres($handler->(+{PATH_INFO => 't/../../../etc/passwd.t'}));
        is $res->code, 404, 'not found & traversal';
        is $res->content, 'not found';
    };

    do {
        my $res = psgi2hres($handler->(+{PATH_INFO => '../Makefile.PL'}));
        is $res->code, 403, 'directory traversal';
        is $res->content, 'forbidden';
    };

    do {
        my $res = psgi2hres($handler->(+{PATH_INFO => 'not_found.t'}));
        is $res->code, 404, 'not found';
        is $res->content, 'not found';
    };

    do {
        my $res = psgi2hres($handler->(+{PATH_INFO => 'assets/face.jpg'}));
        is $res->content_type, 'image/jpeg';
    };

    done_testing;
}

sub psgi2hres {
    my $res = shift;
    return HTTP::Response->new($res->[0], $res->[0], $res->[1], get_body($res));
}

sub get_body {
    my $res = shift;
    my $body = '';
    Plack::Util::foreach($res->[2], sub { $body .= $_[0] });
    $body;
}

