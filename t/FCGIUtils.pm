package t::FCGIUtils;
use strict;
use warnings;
use File::Temp ();
use FindBin;
use Test::More;
use IO::Socket;
use File::Spec;
use Test::TCP qw/test_tcp empty_port/;
use parent qw/Exporter/;

# this file is copied from Catalyst. thanks!

our @EXPORT = qw/ test_lighty_external test_fcgi_standalone /;

# TODO: tesst for .fcgi 
sub test_lighty_fcgi {

}

# test using FCGI::Client + FCGI External Server
sub test_fcgi_standalone {
    my ($callback, $http_port, $fcgi_port) = @_;

    $http_port ||= empty_port();
    $fcgi_port ||= empty_port($http_port);

    require Plack::App::FCGIDispatcher;
    my $fcgi_app = Plack::App::FCGIDispatcher->new({ port => $fcgi_port })->to_app;

    test_tcp(
        server => sub {
            my $server = Plack::Loader->load('Standalone', host => '127.0.0.1', port => $http_port);
            $server->run($fcgi_app);
        },
        client => sub {
            $callback->($http_port, $fcgi_port);
        },
        port => $http_port,
    );
}

# test for FCGI External Server
sub test_lighty_external (&@) {
    my ($callback, $lighty_port, $fcgi_port) = @_;

    $lighty_port ||= empty_port();
    $fcgi_port   ||= empty_port($lighty_port);

    my $lighttpd_bin = $ENV{LIGHTTPD_BIN} || `which lighttpd`;
    chomp $lighttpd_bin;

    plan skip_all => 'Please set LIGHTTPD_BIN to the path to lighttpd'
        unless $lighttpd_bin && -x $lighttpd_bin;

    my $ver = (`$lighttpd_bin -v` =~ /lighttpd-1.(\d+\.\d+)/)[0];

    my $tmpdir = File::Temp::tempdir( CLEANUP => 1 );

    test_tcp(
        client => sub {
            $callback->($lighty_port, $fcgi_port, $ver < 4.23);
            warn `cat $tmpdir/error.log` if $ENV{DEBUG};
        },
        server => sub {
            my $conffname = File::Spec->catfile($tmpdir, "lighty.conf");
            _write_file($conffname => _render_conf($tmpdir, $lighty_port, $fcgi_port));

            my $pid = open my $lighttpd, "$lighttpd_bin -D -f $conffname 2>&1 |" 
                or die "Unable to spawn lighttpd: $!";
            $SIG{TERM} = sub {
                kill 'INT', $pid;
                close $lighttpd;
                exit;
            };
            sleep 60; # waiting tests.
            die "server timeout";
        },
        port => $lighty_port,
    );
}

sub _write_file {
    my ($fname, $src) = @_;
    open my $fh, '>', $fname or die $!;
    print {$fh} $src or die $!;
    close $fh;
}

sub _render_conf {
    my ($tmpdir, $port, $fcgiport) = @_;
    <<"END";
# basic lighttpd config file for testing fcgi(external server)+Plack
server.modules += ("mod_fastcgi")

server.document-root = "$tmpdir"

server.bind = "127.0.0.1"
server.port = $port

# HTTP::Engine app specific fcgi setup
fastcgi.server = (
    "" => ((
            "check-local"     => "disable",
            "host"            => "127.0.0.1",
            "port"            => $fcgiport,
            "idle-timeout"    => 20,
            "fix-root-scriptname" => "enable", # for 1.4.23 or later
    ))
)
END
}

1;
