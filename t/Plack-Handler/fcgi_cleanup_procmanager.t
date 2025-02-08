use strict;
use warnings;
use Test::More;

plan skip_all => "release test only" unless $ENV{RELEASE_TESTING};

use Test::Exit; # before FCGI::ProcManager that calls exit
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

            ok $c{handled}, "Cleanup handler ran successfully even though pm_post_dispatch handled TERM signal";
            ok !$c{handled_term}, "Didn't trigger our TERM cleanup_handler";
            ok !$c{response_cb}{ran}, "> had not run in response_cb";

            is $c{response_cb}{handler_count}, 1,
                "1 handler set up in response_cb, the TERM handler wasn't";

            is $c{exit_code}, 0,
                "proc_manager exited with 0";
        },
        client => sub {
            # my ($port) = @_; Need to use the $lighty_port

            my $ua = LWP::UserAgent->new( timeout => $ua_timeout );
            my $res = $ua->get("http://127.0.0.1:$lighty_port/");
            my $response_received = time;
            ok $res->is_success, "Got successful response";
            my $handled = $res->content;
            is $handled, '0', "With response indicating not yet cleaned up";

            # have to make the client wait until the server has exited
            # otherwise the FCGI gets confused by sending a TERM
            # that doesn't get handled right away.
            sleep 1;
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

        my $SIG_TERM;
        local $SIG{TERM} = sub { $SIG_TERM->() if $SIG_TERM };

        # An app inside an faux middleware
        my $app = sub {
            my ($env) = @_;

            $SIG_TERM = sub {
                diag "app (pid $$) received signal TERM\n";
                $env->{'psgix.harakiri.commit'} = 1;
                push @{ $env->{'psgix.cleanup.handlers'} }, sub {$r{handled_term} = 1};
            };

            # The app
            my $res = sub {
                my ($env) = @_;

                $r{enabled} = $env->{'psgix.cleanup'};
                push @{ $env->{'psgix.cleanup.handlers'} },
                    sub { $r{handled} = 1 };

                kill TERM => $$; # trigger ProcManager TERM handler

                # Use streaming response to verify that cleanup happens
                # even after that.
                sub { shift->( [ 200, [], [ $r{handled} ] ] ) }
            }->($env);

            Plack::Util::response_cb( $res, sub {
                $r{response_cb} = {
                    enabled => $env->{'psgix.cleanup'},
                    ran     => $r{handled},
                    handler_count =>
                        scalar @{ $env->{'psgix.cleanup.handlers'} },
                };
            } );
        };

        if ($needs_fix) {
            note "Applying LighttpdScriptNameFix";
            $app = Plack::Middleware::LighttpdScriptNameFix->wrap($app);
        }

        $| = 0;    # Test::Builder autoflushes this. reset!

        # Initialize a ProcManager that's only a "server"
        # without the "manager" part that forks.
        my $manager = FCGI::ProcManager->new({ n_process => 0 });
        delete $manager->{PIDS};
        $manager->role("server");
        $manager->handling_init;
        $manager->pm_notify("initialized");

        my $fcgi = Plack::Handler::FCGI->new(
            manager     => $manager,
            host        => '127.0.0.1',
            port        => $port,
            keep_stderr => 1,
        );

        $r{exit_code} = exit_code { $fcgi->run($app) };

        return %r;
    };
}
