use strict;
use warnings;
use Test::More;

plan skip_all => "release test only" unless $ENV{RELEASE_TESTING};

use Test::Requires qw(FCGI FCGI::ProcManager LWP::UserAgent);
use Plack;
use Plack::Util;
use Plack::Handler::FCGI;
use Test::TCP;
use lib 't/Plack-Handler';
use FCGIUtils;

my $ua_timeout = 3;

test_lighty_external( sub {
    my ($lighty_port, $fcgi_port, $needs_fix) = @_;

    test_tcp(
        port   => $fcgi_port,
        server => sub {
            my ($port) = @_;
            my %c = run_server_cb($needs_fix)->($port);

            ok $c{enabled}, "Cleanup extension is enabled";
            ok $c{before}{enabled},      "> was enabled before";
            ok $c{response_cb}{enabled}, "> still enabled in response_cb";

            ok $c{before}{handler_set_up}, "Handler was an arrayref before";

            ok $c{handled}, "Cleanup handler ran successfully";
            ok !$c{before}{ran},      "> had not run before";
            ok !$c{response_cb}{ran}, "> had not run in response_cb";

            ok $c{before}{handled},      "Ran handler set up before";
            ok $c{response_cb}{handled}, "Ran handler set up in response_cb";

            ok !$c{before}{handler_count}, "No handlers before";
            is $c{response_cb}{handler_count}, 2,
                "One handler entered response_cb";

            ok $c{response_cb}{handled} - $c{before}{handled} >= 3,
                "Before handler at least three seconds before response_cb";
        },
        client => sub {
            # my ($port) = @_; Need to use the $lighty_port

            my $ua = LWP::UserAgent->new( timeout => $ua_timeout );
            my $res = $ua->get("http://127.0.0.1:$lighty_port/");
            my $response_received = time;
            ok $res->is_success, "Got successful response";
            my ($handled, $response_sent) = split /:/, $res->content;
            is $handled, '0', "With response indicating not yet cleaned up";
            ok $response_received - $response_sent <= 1,
                "Response received within a second of being sent";

            # have to make the client wait until the server has exited
            # otherwise the FCGI gets confused by sending a TERM
            # that doesn't get handled right away.
            sleep 5;
        },
    );
} );

done_testing();

sub run_server_cb {
    my $needs_fix = shift;

    require Plack::Middleware::LighttpdScriptNameFix;
    return sub {
        my ($port) = @_;

        my %r = ( handled => 0 );

        # An app inside an faux middleware
        my $app = sub {
            my ($env) = @_;

            local $SIG{TERM} = sub {
                diag "app (pid $$) received signal TERM\n";
                $env->{'psgix.harakiri.commit'} = 1;
                push @{ $env->{'psgix.cleanup.handlers'} }, sub {exit};
            };

            $r{before} = {
                enabled       => $env->{'psgix.cleanup'},
                ran           => $r{handled},
                handler_count => scalar @{ $env->{'psgix.cleanup.handlers'} },
                handler_set_up =>
                    ref $env->{'psgix.cleanup.handlers'} eq 'ARRAY',
            };

            push @{ $env->{'psgix.cleanup.handlers'} },
                sub { $r{before}{handled} = time };

            # The app
            my $res = sub {
                my ($env) = @_;

                $r{enabled} = $env->{'psgix.cleanup'};
                push @{ $env->{'psgix.cleanup.handlers'} },
                    sub { sleep 3; $r{handled} = time };

                # Use streaming response to verify that cleanup happens
                # even after that.
                sub { shift->( [ 200, [], [ $r{handled} . ':' . time ] ] ) }
            }->($env);

            Plack::Util::response_cb( $res, sub {
                $r{response_cb} = {
                    enabled => $env->{'psgix.cleanup'},
                    ran     => $r{handled},
                    handler_count =>
                        scalar @{ $env->{'psgix.cleanup.handlers'} },
                };
                push @{ $env->{'psgix.cleanup.handlers'} },
                    sub { $r{response_cb}{handled} = time };
            } );
        };

        if ($needs_fix) {
            note "Applying LighttpdScriptNameFix";
            $app = Plack::Middleware::LighttpdScriptNameFix->wrap($app);
        }

        $| = 0;    # Test::Builder autoflushes this. reset!

        Plack::Handler::FCGI->new(
            host        => '127.0.0.1',
            port        => $port,
            keep_stderr => 1,
        )->run($app);

        return %r;
    };
}


