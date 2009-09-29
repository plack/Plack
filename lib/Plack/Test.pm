package Plack::Test;
use strict;
use warnings;
use Digest::MD5;
use HTTP::Request;
use HTTP::Request::Common;
use LWP::UserAgent;
use Test::More;
use Test::TCP;
use Plack::Loader;
use Plack::Lint;

our $BaseDir = "t";

# 0: test name
# 1: request generator coderef.
# 2: request handler
# 3: test case for response
our @TEST = (
    [
        'GET',
        sub {
            my $port = $_[0] || 80;
            HTTP::Request->new(GET => "http://127.0.0.1:$port/?name=miyagawa");
        },
        sub {
            my $env = shift;
            return [
                200,
                [ 'Content-Type' => 'text/plain', ],
                [ 'Hello, ' . $env->{QUERY_STRING} ],
            ];
        },
        sub {
            my $res = shift;
            is $res->code, 200;
            is $res->header('content_type'), 'text/plain';
            is $res->content, 'Hello, name=miyagawa';
        }
    ],
    [
        'POST',
        sub {
            my $port = shift || 80;
            POST("http://127.0.0.1:$port/", [name => 'tatsuhiko']);
        },
        sub {
            my $env = shift;
            is($env->{CONTENT_LENGTH}, 14);
            is($env->{CONTENT_TYPE}, 'application/x-www-form-urlencoded');
            my $body;
            $env->{'psgi.input'}->read($body, $env->{CONTENT_LENGTH});
            return [
                200,
                [ 'Content-Type' => 'text/plain', ],
                [ 'Hello, ' . $body ],
            ];
        },
        sub {
            my $res = shift;
            is $res->code, 200;
            is $res->header('content_type'), 'text/plain';
            is $res->content, 'Hello, name=tatsuhiko';
        }
    ],
    [
        'psgi.url_scheme',
        sub {
            my $port = shift || 80;
            POST("http://127.0.0.1:$port/");
        },
        sub {
            my $env = $_[0];
            return [
                200,
                [ 'Content-Type' => 'text/plain', ],
                [ $env->{'psgi.url_scheme'} ],
            ];
        },
        sub {
            my $res = shift;
            is $res->code, 200;
            is $res->header('content_type'), 'text/plain';
            is $res->content, 'http';
        }
    ],
    [
        'return glob',
        sub {
            my $port = $_[0] || 80;
            HTTP::Request->new(GET => "http://127.0.0.1:$port/");
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
        sub {
            my $res = shift;
            is $res->code, 200;
            is $res->header('content_type'), 'text/plain';
            like $res->content, qr/^package /;
            like $res->content, qr/END_MARK_FOR_TESTING$/;
        }
    ],
    [
        'filehandle',
        sub {
            my $port = $_[0] || 80;
            HTTP::Request->new(
                GET => "http://127.0.0.1:$port/foo.jpg",
            );
        },
        sub {
            my $env = shift;
            open my $fh, '<', "$BaseDir/assets/face.jpg";
            return [
                200,
                [ 'Content-Type' => 'image/jpeg', 'Content-Length' => -s $fh ],
                $fh
            ];
        },
        sub {
            my $res = shift;
            my $port = shift || 80;
            is $res->code, 200;
            is $res->header('content_type'), 'image/jpeg';
            is length $res->content, 4745;
        },
    ],
    [
        'bigger file',
        sub {
            my $port = $_[0] || 80;
            HTTP::Request->new(
                GET => "http://127.0.0.1:$port/kyoto.jpg",
            );
        },
        sub {
            my $env = shift;
            open my $fh, '<', "$BaseDir/assets/kyoto.jpg";
            return [
                200,
                [ 'Content-Type' => 'image/jpeg', 'Content-Length' => -s $fh ],
                $fh
            ];
        },
        sub {
            my $res = shift;
            my $port = shift || 80;
            is $res->code, 200;
            is $res->header('content_type'), 'image/jpeg';
            is length $res->content, 2397701;
            is Digest::MD5::md5_hex($res->content), '9c6d7249a77204a88be72e9b2fe279e8';
        },
    ],
    [
        'handle HTTP-Header',
        sub {
            my $port = $_[0] || 80;
            HTTP::Request->new(
                GET => "http://127.0.0.1:$port/foo/?dankogai=kogaidan",
                HTTP::Headers->new( 'Foo' => 'Bar' )
            );
        },
        sub {
            my $env = shift;
            return [
                200,
                [ 'Content-Type' => 'text/plain', ],
                [$env->{HTTP_FOO}],
            ];
        },
        sub {
            my $res = shift;
            my $port = shift || 80;
            is $res->code, 200;
            is $res->header('content_type'), 'text/plain';
            is $res->content, 'Bar';
        }
    ],
    [
        'handle HTTP-Cookie',
        sub {
            my $port = $_[0] || 80;
            HTTP::Request->new(
                GET => "http://127.0.0.1:$port/foo/?dankogai=kogaidan",
                HTTP::Headers->new( 'Cookie' => 'foo' )
            );
        },
        sub {
            my $env = shift;
            return [
                200,
                [ 'Content-Type' => 'text/plain', ],
                [$env->{HTTP_COOKIE}],
            ];
        },
        sub {
            my $res = shift;
            my $port = shift || 80;
            is $res->code, 200;
            is $res->header('content_type'), 'text/plain';
            is $res->content, 'foo';
        }
    ],
    [
        'validate env',
        sub {
            my $port = $_[0] || 80;
            HTTP::Request->new(
                GET => "http://127.0.0.1:$port/foo/?dankogai=kogaidan",
            );
        },
        sub {
            my $env = shift;
            my $body;
            $body .= $_ . ':' . $env->{$_} . "\n" for qw/REQUEST_METHOD PATH_INFO QUERY_STRING SERVER_NAME SERVER_PORT/;
            return [
                200,
                [ 'Content-Type' => 'text/plain', ],
                [$body],
            ];
        },
        sub {
            my $res = shift;
            my $port = shift || 80;
            is $res->code, 200;
            is $res->header('content_type'), 'text/plain';
            is $res->content, join("\n",
                'REQUEST_METHOD:GET',
                'PATH_INFO:/foo/',
                'QUERY_STRING:dankogai=kogaidan',
                'SERVER_NAME:127.0.0.1',
                "SERVER_PORT:$port",
            )."\n";
        }
    ],
    [
        '% encoding in PATH_INFO',
        # Apache mod_cgi has a bug decoding all % encoded strings
        sub {
            my $port = $_[0] || 80;
            HTTP::Request->new(
                GET => "http://127.0.0.1:$port/foo/bar%2Fbaz",
            );
        },
        sub {
            my $env = shift;
            return [
                200,
                [ 'Content-Type' => 'text/plain', ],
                [ $env->{PATH_INFO} ],
            ];
        },
        sub {
            my $res = shift;
            is $res->content, "/foo/bar/baz", "PATH_INFO should be decoded per RFC 3875";
        }
    ],
    [
        'SERVER_PROTOCOL is required',
        sub {
            my $port = $_[0] || 80;
            HTTP::Request->new(
                GET => "http://127.0.0.1:$port/foo/?dankogai=kogaidan",
            );
        },
        sub {
            my $env = shift;
            return [
                200,
                [ 'Content-Type' => 'text/plain', ],
                [$env->{SERVER_PROTOCOL}],
            ];
        },
        sub {
            my $res = shift;
            my $port = shift || 80;
            is $res->code, 200;
            is $res->header('content_type'), 'text/plain';
            like $res->content, qr{^HTTP/1\.[01]$};
        }
    ],
    [
        'SCRIPT_NAME should not be undef',
        sub {
            my $port = $_[0] || 80;
            HTTP::Request->new(
                GET => "http://127.0.0.1:$port/foo/?dankogai=kogaidan",
            );
        },
        sub {
            my $env = shift;
            ok defined($env->{'SCRIPT_NAME'});
            return [
                200,
                [ 'Content-Type' => 'text/plain', ],
                [1],
            ];
        },
        sub { }
    ],
    [
        # PEP-333 says:
        #    If the iterable returned by the application has a close() method,
        #   the server or gateway must call that method upon completion of the
        #   current request, whether the request was completed normally, or
        #   terminated early due to an error. 
        'call close after read file-like',
        sub {
            my $port = $_[0] || 80;
            HTTP::Request->new(
                GET => "http://127.0.0.1:$port/call_close",
            );
        },
        sub {
            my $env = shift;
            {
                package CalledClose;
                our $closed = -1;
                sub new { $closed = 0; my $i=0; bless \$i, 'CalledClose' }
                sub getline {
                    my $self = shift;
                    return $$self++ < 4 ? $$self : undef;
                }
                sub close     { ::ok(1, 'closed') if defined &::ok }
            }
            return [
                200,
                [ 'Content-Type' => 'text/plain', ],
                CalledClose->new(),
            ];
        },
        sub {
            my $res = shift;
            is($res->content, '1234');
        }
    ],
    [
        'has errors',
        sub {
            my $port = $_[0] || 80;
            HTTP::Request->new(
                GET => "http://127.0.0.1:$port/has_errors",
            );
        },
        sub {
            my $env = shift;
            my $err = $env->{'psgi.errors'};
            ok $err;
            return [
                200,
                [ 'Content-Type' => 'text/plain', ],
                [1]
            ];
        },
        sub { }
    ],
    [
        'status line',
        sub {
            my $port = $_[0] || 80;
            HTTP::Request->new(
                GET => "http://127.0.0.1:$port/foo/?dankogai=kogaidan",
            );
        },
        sub {
            my $env = shift;
            my $err = $env->{'psgi.errors'};
            ok $err;
            return [
                200,
                [ 'Content-Type' => 'text/plain', ],
                [1]
            ];
        },
        sub {
            my $res = shift;
            is($res->status_line, '200 OK');
        }
    ],
    [
        'Do not crash when the app dies',
        sub {
            my $port = $_[0] || 80;
            HTTP::Request->new(
                GET => "http://127.0.0.1:$port/",
            );
        },
        sub {
            my $env = shift;
            die "Throwing an exception from app handler. Server shouldn't crash.";
        },
        sub {
            my $res = shift;
            is $res->code, 500;
        }
    ],
    [
        'multi headers',
        sub {
            my $port = $_[0] || 80;
            my $req = HTTP::Request->new(
                GET => "http://127.0.0.1:$port/",
            );
            $req->push_header(Foo => "bar");
            $req->push_header(Foo => "baz");
            $req;
        },
        sub {
            my $env = shift;
            return [
                200,
                [ 'Content-Type' => 'text/plain', ],
                [ $env->{HTTP_FOO} ]
            ];
        },
        sub {
            my $res = shift;
            is($res->content, "bar, baz");
        }
    ],
    [
        'no entity headers on 304',
        sub {
            my $port = $_[0] || 80;
            HTTP::Request->new(
                GET => "http://127.0.0.1:$port/",
            );
        },
        sub {
            my $env = shift;
            return [ 304, [], [] ];
        },
        sub {
            my $res = shift;
            is $res->code, 304;
            is $res->content, '';
            ok ! defined $res->header('content_type'), "No Content-Type";
            ok ! defined $res->header('content_length'), "No Content-Length";
            ok ! defined $res->header('transfer_encoding'), "No Transfer-Encoding";
        },
    ],
);

for my $test (@TEST) {
    my $orig = $test->[2];
    $test->[2] = sub {
        {
            local $Carp::CarpLevel = $Carp::CarpLevel + 1;
            Plack::Lint->validate_env( $_[0] );
        }
        my $res = $orig->(@_);
        {
            local $Carp::CarpLevel = $Carp::CarpLevel + 1;
            Plack::Lint->validate_res($res);
        }
        return $res;
    };
}


sub runtests {
    my($class, $runner) = @_;
    for my $test (@TEST) {
        $runner->(@$test);
    }
}

sub run_server_tests {
    my($class, $server, $server_port, $http_port) = @_;

    if (ref $server ne 'CODE') {
        my $server_class = $server;
        $server = sub {
            my($port, $app) = @_;
            my $server = Plack::Loader->load($server_class, port => $port, host => "127.0.0.1");
            $server->run($app);
            $server->run_loop if $server->can('run_loop');
        }
    }

    test_tcp(
        client => sub {
            my $port = $http_port || shift;
            for my $i (0..$#TEST) {
                my $test = $TEST[$i];
                note $test->[0];
                my $ua  = LWP::UserAgent->new;
                my $req = $test->[1]->($port);
                $req->header('X-Plack-Test' => $i);
                my $res = $ua->request($req);
                local $Test::Builder::Level = $Test::Builder::Level + 3;
                $test->[3]->($res, $port);
            }
        },
        server => sub {
            my $port = shift;
            my $app = sub {
                my $env = shift;
                $TEST[$env->{HTTP_X_PLACK_TEST}][2]->($env);
            };
            $server->($port, $app);
        },
        port => $server_port,
    );
}

1;
__END__

=head1 SYNOPSIS

    see tests.

=head1 DESCRIPTION

Test suite for the PSGI spec. This will rename to the PSGI::TestSuite or something.

=head1 METHODS

=over 4

=item count

count the test cases.

=item my ($name, $reqgen, $handler, $test) = Plack::Test->get_test($i)

=back

=cut

END_MARK_FOR_TESTING
