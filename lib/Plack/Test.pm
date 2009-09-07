package Plack::Test;
use strict;
use warnings;
use HTTP::Request;
use HTTP::Request::Common;
use HTTP::Headers::Fast;
use Test::More;
use Plack::Lint;

# 0: test name
# 1: request generator coderef.
# 2: request handler
# 3: test case for response
my @TEST = (
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
                GET => "http://127.0.0.1:$port/foo/?dankogai=kogaidan",
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
                sub close     { ::ok(1, 'closed') }
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
        sub { }
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
