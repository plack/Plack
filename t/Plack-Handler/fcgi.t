use strict;
use warnings;
use Test::More;

plan skip_all => "release test only" unless $ENV{RELEASE_TESTING};

use Test::Requires qw(FCGI FCGI::ProcManager);
use Plack;
use Plack::Handler::FCGI;
use Plack::Test::Suite;
use lib 't/Plack-Handler';
use FCGIUtils;

my $lighty_port;
my $fcgi_port;

for my $script_name ('', '/fastcgi') {
    $ENV{PLACK_TEST_SCRIPT_NAME} = $script_name;
    test_lighty_external(
        sub {
            ($lighty_port, $fcgi_port) = (shift, shift);
            my $needs_fix = $script_name eq '' ? shift : 0;
            Plack::Test::Suite->run_server_tests(run_server_cb($needs_fix), $fcgi_port, $lighty_port);
        }
    );
}

done_testing();

{
    package Plack::Handler::FCGI::Manager;
    use parent qw(FCGI::ProcManager);
    sub pm_post_dispatch {
        my $self = shift;
        ${ $self->{dispatched} }++;
        $self->SUPER::pm_post_dispatch(@_);
    }
}

sub run_server_cb {
    my $needs_fix = shift;

    require Plack::Middleware::LighttpdScriptNameFix;
    return sub {
        my($port, $app) = @_;

        if ($needs_fix) {
            note "Applying LighttpdScriptNameFix";
            $app = Plack::Middleware::LighttpdScriptNameFix->wrap($app);
        }

        $| = 0; # Test::Builder autoflushes this. reset!

        my $d;
        my $manager = Plack::Handler::FCGI::Manager->new({
            dispatched => \$d,
        });

        my $server = Plack::Handler::FCGI->new(
            host        => '127.0.0.1',
            port        => $port,
            manager     => $manager,
            keep_stderr => 1,
        );
        $server->run($app);
        ok($d > 0, "FCGI manager object state updated");
    };
}


