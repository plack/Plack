package Plack::Test::Suite;
use strict;
use warnings;
use Digest::MD5;
use File::ShareDir;
use HTTP::Request;
use HTTP::Request::Common;
use Test::More;
use Test::TCP;
use Plack::Loader;
use Plack::Middleware::Lint;
use Plack::Util;
use Plack::Request;
use Try::Tiny;
use Plack::LWPish;

my $share_dir = try { File::ShareDir::dist_dir('Plack') } || 'share';

$ENV{PLACK_TEST_SCRIPT_NAME} = '';

# 0: test name
# 1: request generator coderef.
# 2: request handler
# 3: test case for response
our @TEST = (
    [
        'SCRIPT_NAME',
        sub {
            my $cb = shift;
            my $res = $cb->(GET "http://127.0.0.1/");
            is $res->content, "script_name=$ENV{PLACK_TEST_SCRIPT_NAME}";
        },
        sub {
            my $env = shift;
            return [ 200, ["Content-Type", "text/plain"], [ "script_name=$env->{SCRIPT_NAME}" ] ];
        },
    ],
    [
        'GET',
        sub {
            my $cb = shift;
            my $res = $cb->(GET "http://127.0.0.1/?name=miyagawa");
            is $res->code, 200;
            is $res->message, 'OK';
            is $res->header('content_type'), 'text/plain';
            is $res->content, 'Hello, name=miyagawa';
        },
        sub {
            my $env = shift;
            return [
                200,
                [ 'Content-Type' => 'text/plain', ],
                [ 'Hello, ' . $env->{QUERY_STRING} ],
            ];
        },
    ],
    [
        'POST',
        sub {
            my $cb = shift;
            my $res = $cb->(POST "http://127.0.0.1/", [name => 'tatsuhiko']);
            is $res->code, 200;
            is $res->message, 'OK';
            is $res->header('Client-Content-Length'), 14;
            is $res->header('Client-Content-Type'), 'application/x-www-form-urlencoded';
            is $res->header('content_type'), 'text/plain';
            is $res->content, 'Hello, name=tatsuhiko';
        },
        sub {
            my $env = shift;
            my $body;
            $env->{'psgi.input'}->read($body, $env->{CONTENT_LENGTH});
            return [
                200,
                [ 'Content-Type' => 'text/plain',
                  'Client-Content-Length' => $env->{CONTENT_LENGTH},
                  'Client-Content-Type' => $env->{CONTENT_TYPE},
              ],
                [ 'Hello, ' . $body ],
            ];
        },
    ],
    [
        'big POST',
        sub {
            my $cb = shift;
            my $chunk = "abcdefgh" x 12000;
            my $req = HTTP::Request->new(POST => "http://127.0.0.1/");
            $req->content_length(length $chunk);
            $req->content_type('application/octet-stream');
            $req->content($chunk);

            my $res = $cb->($req);
            is $res->code, 200;
            is $res->message, 'OK';
            is $res->header('Client-Content-Length'), length $chunk;
            is length $res->content, length $chunk;
            is Digest::MD5::md5_hex($res->content), Digest::MD5::md5_hex($chunk);
        },
        sub {
            my $env = shift;
            my $len = $env->{CONTENT_LENGTH};
            my $body = '';
            my $spin;
            while ($len > 0) {
                my $rc = $env->{'psgi.input'}->read($body, $env->{CONTENT_LENGTH}, length $body);
                $len -= $rc;
                last if $spin++ > 2000;
            }
            return [
                200,
                [ 'Content-Type' => 'text/plain',
                  'Client-Content-Length' => $env->{CONTENT_LENGTH},
                  'Client-Content-Type' => $env->{CONTENT_TYPE},
              ],
                [ $body ],
            ];
        },
    ],
    [
        'psgi.url_scheme',
        sub {
            my $cb = shift;
            my $res = $cb->(POST "http://127.0.0.1/");
            is $res->code, 200;
            is $res->message, 'OK';
            is $res->header('content_type'), 'text/plain';
            is $res->content, 'http';
        },
        sub {
            my $env = $_[0];
            return [
                200,
                [ 'Content-Type' => 'text/plain', ],
                [ $env->{'psgi.url_scheme'} ],
            ];
        },
    ],
    [
        'return glob',
        sub {
            my $cb  = shift;
            my $res = $cb->(GET "http://127.0.0.1/");
            is $res->code, 200;
            is $res->message, 'OK';
            is $res->header('content_type'), 'text/plain';
            like $res->content, qr/^package /;
            like $res->content, qr/END_MARK_FOR_TESTING$/;
        },
        sub {
            my $env = shift;
            open my $fh, '<', __FILE__ or die $!;
            return [
                200,
                [ 'Content-Type' => 'text/plain', ],
                $fh,
            ];
        },
    ],
    [
        'filehandle',
        sub {
            my $cb  = shift;
            my $res = $cb->(GET "http://127.0.0.1/foo.jpg");
            is $res->code, 200;
            is $res->message, 'OK';
            is $res->header('content_type'), 'image/jpeg';
            is length $res->content, 2898;
        },
        sub {
            my $env = shift;
            open my $fh, '<', "$share_dir/face.jpg";
            return [
                200,
                [ 'Content-Type' => 'image/jpeg', 'Content-Length' => -s $fh ],
                $fh
            ];
        },
    ],
    [
        'bigger file',
        sub {
            my $cb  = shift;
            my $res = $cb->(GET "http://127.0.0.1/baybridge.jpg");
            is $res->code, 200;
            is $res->message, 'OK';
            is $res->header('content_type'), 'image/jpeg';
            is length $res->content, 14750;
            is Digest::MD5::md5_hex($res->content), '70546a79c7abb9c497ca91730a0686e4';
        },
        sub {
            my $env = shift;
            open my $fh, '<', "$share_dir/baybridge.jpg";
            binmode $fh;
            return [
                200,
                [ 'Content-Type' => 'image/jpeg', 'Content-Length' => -s $fh ],
                $fh
            ];
        },
    ],
    [
        'handle HTTP-Header',
        sub {
            my $cb  = shift;
            my $res = $cb->(GET "http://127.0.0.1/foo/?dankogai=kogaidan", Foo => "Bar");
            is $res->code, 200;
            is $res->message, 'OK';
            is $res->header('content_type'), 'text/plain';
            is $res->content, 'Bar';
        },
        sub {
            my $env = shift;
            return [
                200,
                [ 'Content-Type' => 'text/plain', ],
                [$env->{HTTP_FOO}],
            ];
        },
    ],
    [
        'handle HTTP-Cookie',
        sub {
            my $cb  = shift;
            my $res = $cb->(GET "http://127.0.0.1/foo/?dankogai=kogaidan", Cookie => "foo");
            is $res->code, 200;
            is $res->message, 'OK';
            is $res->header('content_type'), 'text/plain';
            is $res->content, 'foo';
        },
        sub {
            my $env = shift;
            return [
                200,
                [ 'Content-Type' => 'text/plain', ],
                [$env->{HTTP_COOKIE}],
            ];
        },
    ],
    [
        'validate env',
        sub {
            my $cb  = shift;
            my $res = $cb->(GET "http://127.0.0.1/foo/?dankogai=kogaidan");
            is $res->code, 200;
            is $res->message, 'OK';
            is $res->header('content_type'), 'text/plain';
            is $res->content, join("\n",
                'REQUEST_METHOD:GET',
                "SCRIPT_NAME:$ENV{PLACK_TEST_SCRIPT_NAME}",
                'PATH_INFO:/foo/',
                'QUERY_STRING:dankogai=kogaidan',
                'SERVER_NAME:127.0.0.1',
                "SERVER_PORT:" . $res->request->uri->port,
            )."\n";
        },
        sub {
            my $env = shift;
            my $body;
            $body .= $_ . ':' . $env->{$_} . "\n" for qw/REQUEST_METHOD SCRIPT_NAME PATH_INFO QUERY_STRING SERVER_NAME SERVER_PORT/;
            return [
                200,
                [ 'Content-Type' => 'text/plain', ],
                [$body],
            ];
        },
    ],
    [
        '% encoding in PATH_INFO',
        sub {
            my $cb  = shift;
            my $res = $cb->(GET "http://127.0.0.1/foo/bar%2cbaz");
            is $res->content, "/foo/bar,baz", "PATH_INFO should be decoded per RFC 3875";
        },
        sub {
            my $env = shift;
            return [
                200,
                [ 'Content-Type' => 'text/plain', ],
                [ $env->{PATH_INFO} ],
            ];
        },
    ],
    [
        '% double encoding in PATH_INFO',
        sub {
            my $cb  = shift;
            my $res = $cb->(GET "http://127.0.0.1/foo/bar%252cbaz");
            is $res->content, "/foo/bar%2cbaz", "PATH_INFO should be decoded only once, per RFC 3875";
        },
        sub {
            my $env = shift;
            return [
                200,
                [ 'Content-Type' => 'text/plain', ],
                [ $env->{PATH_INFO} ],
            ];
        },
    ],
    [
        '% encoding in PATH_INFO (outside of URI characters)',
        sub {
            my $cb  = shift;
            my $res = $cb->(GET "http://127.0.0.1/foo%E3%81%82");
            is $res->content, "/foo\x{e3}\x{81}\x{82}";
        },
        sub {
            my $env = shift;
            return [
                200,
                [ 'Content-Type' => 'text/plain', ],
                [ $env->{PATH_INFO} ],
            ];
        },
    ],
    [
        'SERVER_PROTOCOL is required',
        sub {
            my $cb  = shift;
            my $res = $cb->(GET "http://127.0.0.1/foo/?dankogai=kogaidan");
            is $res->code, 200;
            is $res->message, 'OK';
            is $res->header('content_type'), 'text/plain';
            like $res->content, qr{^HTTP/1\.[01]$};
        },
        sub {
            my $env = shift;
            return [
                200,
                [ 'Content-Type' => 'text/plain', ],
                [$env->{SERVER_PROTOCOL}],
            ];
        },
    ],
    [
        'SCRIPT_NAME should not be undef',
        sub {
            my $cb  = shift;
            my $res = $cb->(GET "http://127.0.0.1/foo/?dankogai=kogaidan");
            is $res->content, 1;
        },
        sub {
            my $env = shift;
            my $cont = defined $env->{'SCRIPT_NAME'};
            return [
                200,
                [ 'Content-Type' => 'text/plain', ],
                [$cont],
            ];
        },
    ],
    [
        'call close after read IO::Handle-like',
        sub {
            my $cb  = shift;
            my $res = $cb->(GET "http://127.0.0.1/call_close");
            is($res->content, '1234');
        },
        sub {
            my $env = shift;
            {
                our $closed = -1;
                sub CalledClose::new { $closed = 0; my $i=0; bless \$i, 'CalledClose' }
                sub CalledClose::getline {
                    my $self = shift;
                    return $$self++ < 4 ? $$self : undef;
                }
                sub CalledClose::close { ::ok(1, 'closed') if defined &::ok }
            }
            return [
                200,
                [ 'Content-Type' => 'text/plain', ],
                CalledClose->new(),
            ];
        },
    ],
    [
        'has errors',
        sub {
            my $cb  = shift;
            my $res = $cb->(GET "http://127.0.0.1/has_errors");
            is $res->content, 1;
        },
        sub {
            my $env = shift;
            my $err = $env->{'psgi.errors'};
            my $has_errors = defined $err;
            return [
                200,
                [ 'Content-Type' => 'text/plain', ],
                [$has_errors]
            ];
        },
    ],
    [
        'status line',
        sub {
            my $cb  = shift;
            my $res = $cb->(GET "http://127.0.0.1/foo/?dankogai=kogaidan");
            is($res->status_line, '200 OK');
        },
        sub {
            my $env = shift;
            return [
                200,
                [ 'Content-Type' => 'text/plain', ],
                [1]
            ];
        },
    ],
    [
        'Do not crash when the app dies',
        sub {
            my $cb  = shift;
            my $res = $cb->(GET "http://127.0.0.1/");
            is $res->code, 500;
            is $res->message, 'Internal Server Error';
        },
        sub {
            my $env = shift;
            open my $io, '>', \my $error;
            $env->{'psgi.errors'} = $io;
            die "Throwing an exception from app handler. Server shouldn't crash.";
        },
    ],
    [
        'multi headers (request)',
        sub {
            my $cb  = shift;
            my $req = HTTP::Request->new(
                GET => "http://127.0.0.1/",
            );
            $req->push_header(Foo => "bar");
            $req->push_header(Foo => "baz");
            my $res = $cb->($req);
            like($res->content, qr/^bar,\s*baz$/);
        },
        sub {
            my $env = shift;
            return [
                200,
                [ 'Content-Type' => 'text/plain', ],
                [ $env->{HTTP_FOO} ]
            ];
        },
    ],
    [
        'multi headers (response)',
        sub {
            my $cb  = shift;
            my $res = $cb->(HTTP::Request->new(GET => "http://127.0.0.1/"));
            my $foo = $res->header('X-Foo');
            like $foo, qr/foo,\s*bar,\s*baz/;
        },
        sub {
            my $env = shift;
            return [
                200,
                [ 'Content-Type' => 'text/plain', 'X-Foo', 'foo', 'X-Foo', 'bar, baz' ],
                [ 'hi' ]
            ];
        },
    ],
    [
        'Do not set $env->{COOKIE}',
        sub {
            my $cb  = shift;
            my $req = HTTP::Request->new(
                GET => "http://127.0.0.1/",
            );
            $req->push_header(Cookie => "foo=bar");
            my $res = $cb->($req);
            is($res->header('X-Cookie'), 0);
            is $res->content, 'foo=bar';
        },
        sub {
            my $env = shift;
            return [
                200,
                [ 'Content-Type' => 'text/plain', 'X-Cookie' => $env->{COOKIE} ? 1 : 0 ],
                [ $env->{HTTP_COOKIE} ]
            ];
        },
    ],
    [
        'no entity headers on 304',
        sub {
            my $cb  = shift;
            my $res = $cb->(GET "http://127.0.0.1/");
            is $res->code, 304;
            is $res->message, 'Not Modified';
            is $res->content, '';
            ok ! defined $res->header('content_type'), "No Content-Type";
            ok ! defined $res->header('content_length'), "No Content-Length";
            ok ! defined $res->header('transfer_encoding'), "No Transfer-Encoding";
        },
        sub {
            my $env = shift;
            return [ 304, [], [] ];
        },
    ],
    [
        'REQUEST_URI is set',
        sub {
            my $cb  = shift;
            my $res = $cb->(GET "http://127.0.0.1/foo/bar%20baz%73?x=a");
            is $res->content, $ENV{PLACK_TEST_SCRIPT_NAME} . "/foo/bar%20baz%73?x=a";
        },
        sub {
            my $env = shift;
            return [ 200, [ 'Content-Type' => 'text/plain' ], [ $env->{REQUEST_URI} ] ];
        },
    ],
    [
        'filehandle with path()',
        sub {
            my $cb  = shift;
            my $res = $cb->(GET "http://127.0.0.1/foo.jpg");
            is $res->code, 200;
            is $res->message, 'OK';
            is $res->header('content_type'), 'image/jpeg';
            is length $res->content, 2898;
        },
        sub {
            my $env = shift;
            open my $fh, '<', "$share_dir/face.jpg";
            Plack::Util::set_io_path($fh, "$share_dir/face.jpg");
            return [
                200,
                [ 'Content-Type' => 'image/jpeg', 'Content-Length' => -s $fh ],
                $fh
            ];
        },
    ],
    [
        'a big header value > 128 bytes',
        sub {
            my $cb  = shift;
            my $req = GET "http://127.0.0.1/";
            my $v = ("abcdefgh" x 16);
            $req->header('X-Foo' => $v);
            my $res = $cb->($req);
            is $res->code, 200;
            is $res->message, 'OK';
            is $res->content, $v;
        },
        sub {
            my $env = shift;
            return [
                200,
                [ 'Content-Type' => 'text/plain' ],
                [ $env->{HTTP_X_FOO} ],
            ];
        },
    ],
    [
        'coderef res',
        sub {
            my $cb = shift;
            my $res = $cb->(GET "http://127.0.0.1/?name=miyagawa");
            return if $res->code == 501;

            is $res->code, 200;
            is $res->message, 'OK';
            is $res->header('content_type'), 'text/plain';
            is $res->content, 'Hello, name=miyagawa';
        },
        sub {
            my $env = shift;
            $env->{'psgi.streaming'} or return [ 501, ['Content-Type','text/plain'], [] ];
            return sub {
                my $respond = shift;
                $respond->([
                    200,
                    [ 'Content-Type' => 'text/plain', ],
                    [ 'Hello, ' . $env->{QUERY_STRING} ],
                ]);
            }
        },
    ],
    [
        'coderef streaming',
        sub {
            my $cb = shift;
            my $res = $cb->(GET "http://127.0.0.1/?name=miyagawa");
            return if $res->code == 501;

            is $res->code, 200;
            is $res->message, 'OK';
            is $res->header('content_type'), 'text/plain';
            is $res->content, 'Hello, name=miyagawa';
        },
        sub {
            my $env = shift;
            $env->{'psgi.streaming'} or return [ 501, ['Content-Type','text/plain'], [] ];

            return sub {
                my $respond = shift;

                my $writer = $respond->([
                    200,
                    [ 'Content-Type' => 'text/plain', ],
                ]);

                $writer->write("Hello, ");
                $writer->write($env->{QUERY_STRING});
                $writer->close();
            }
        },
    ],
    [
        'CRLF output and FCGI parse bug',
        sub {
            my $cb = shift;
            my $res = $cb->(GET "http://127.0.0.1/");

            is $res->header("Foo"), undef;
            is $res->content, "Foo: Bar\r\n\r\nHello World";
        },
        sub {
            return [ 200, [ "Content-Type", "text/plain" ], [ "Foo: Bar\r\n\r\nHello World" ] ];
        },
    ],
    [
        'newlines',
        sub {
            my $cb = shift;
            my $res = $cb->(GET "http://127.0.0.1/");
            is length($res->content), 7;
        },
        sub {
            return [ 200, [ "Content-Type", "text/plain" ], [ "Bar\nBaz" ] ];
        },
    ],
    [
        'test 404',
        sub {
            my $cb = shift;
            my $res = $cb->(GET "http://127.0.0.1/");
            is $res->code, 404;
            is $res->message, 'Not Found';
            is $res->content, 'Not Found';
        },
        sub {
            return [ 404, [ "Content-Type", "text/plain" ], [ "Not Found" ] ];
        },
    ],
    [
        'request->input seekable',
        sub {
            my $cb = shift;
            my $req = HTTP::Request->new(POST => "http://127.0.0.1/");
            $req->content("body");
            $req->content_type('text/plain');
            $req->content_length(4);
            my $res = $cb->($req);
            is $res->content, 'body';
        },
        sub {
            my $req = Plack::Request->new(shift);
            return [ 200, [ "Content-Type", "text/plain" ], [ $req->content ] ];
        },
    ],
    [
        'request->content on GET',
        sub {
            my $cb = shift;
            my $res = $cb->(GET "http://127.0.0.1/");
            ok $res->is_success;
        },
        sub {
            my $req = Plack::Request->new(shift);
            $req->content;
            return [ 200, [ "Content-Type", "text/plain" ], [ "OK" ] ];
        },
    ],
    [
        'handle Authorization header',
        sub {
            my $cb  = shift;
            SKIP: {
                skip "Authorization header is unsupported under CGI", 4 if ($ENV{PLACK_TEST_HANDLER} || "") eq "CGI";

                {
                    my $req = HTTP::Request->new(
                        GET => "http://127.0.0.1/",
                    );
                    $req->push_header(Authorization => 'Basic XXXX');
                    my $res = $cb->($req);
                    is $res->header('X-AUTHORIZATION'), 1;
                    is $res->content, 'Basic XXXX';
                };

                {
                    my $req = HTTP::Request->new(
                        GET => "http://127.0.0.1/",
                    );
                    my $res = $cb->($req);
                    is $res->header('X-AUTHORIZATION'), 0;
                    is $res->content, 'no_auth';
                };
            };
        },
        sub {
            my $env = shift;
            return [
                200,
                [ 'Content-Type' => 'text/plain', 'X-AUTHORIZATION' => exists($env->{HTTP_AUTHORIZATION}) ? 1 : 0 ],
                [ $env->{HTTP_AUTHORIZATION} || 'no_auth' ],
            ];
        },
    ],
    [
        'repeated slashes',
        sub {
            my $cb = shift;
            my $res = $cb->(GET "http://127.0.0.1//foo///bar/baz");
            is $res->code, 200;
            is $res->message, 'OK';
            is $res->header('content_type'), 'text/plain';
            is $res->content, '//foo///bar/baz';
        },
        sub {
            my $env = shift;
            return [
                200,
                [ 'Content-Type' => 'text/plain', ],
                [ $env->{PATH_INFO} ],
            ];
        },
    ],
);

sub runtests {
    my($class, $runner) = @_;
    for my $test (@TEST) {
        $runner->(@$test);
    }
}

sub run_server_tests {
    my($class, $server, $server_port, $http_port, %args) = @_;

    if (ref $server ne 'CODE') {
        my $server_class = $server;
        $server = sub {
            my($port, $app) = @_;
            my $server = Plack::Loader->load($server_class, port => $port, host => "127.0.0.1", %args);
            $app = Plack::Middleware::Lint->wrap($app);
            $server->run($app);
        }
    }

    test_tcp(
        client => sub {
            my $port = shift;
            my $ua = Plack::LWPish->new( no_proxy => [qw/127.0.0.1/] );
            for my $i (0..$#TEST) {
                my $test = $TEST[$i];
                note $test->[0];
                my $cb = sub {
                    my $req = shift;
                    $req->uri->port($http_port || $port);
                    $req->uri->path(($ENV{PLACK_TEST_SCRIPT_NAME}||"") . $req->uri->path);
                    $req->header('X-Plack-Test' => $i);
                    return $ua->request($req);
                };

                $test->[1]->($cb);
            }
        },
        server => sub {
            my $port = shift;
            my $app  = $class->test_app_handler;
            $server->($port, $app);
            exit(0); # for Test::TCP
        },
        port => $server_port,
    );
}

sub test_app_handler {
    return sub {
        my $env = shift;
        $TEST[$env->{HTTP_X_PLACK_TEST}][2]->($env);
    };
}

1;
__END__

=head1 NAME

Plack::Test::Suite - Test suite for Plack handlers

=head1 SYNOPSIS

  use Test::More;
  use Plack::Test::Suite;
  Plack::Test::Suite->run_server_tests('Your::Handler');
  done_testing;

=head1 DESCRIPTION

Plack::Test::Suite is a test suite to test a new PSGI server
implementation. It automatically loads a new handler environment and
uses LWP to send HTTP requests to the local server to make sure your
handler implements the PSGI specification correctly.

Note that the handler name doesn't include the C<Plack::Handler::>
prefix, i.e. if you have a new Plack handler Plack::Handler::Foo, your
test script would look like:

  Plack::Test::Suite->run_server_tests('Foo');

Developers writing Plack applications should look at C<Plack::Test> for testing,
as subclassing C<Plack::Handler> is for developing server implementations.

=head1 AUTHOR

Tokuhiro Matsuno

Tatsuhiko Miyagawa

Kazuho Oku

=cut

END_MARK_FOR_TESTING
