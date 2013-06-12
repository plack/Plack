use strict;
use warnings;
use File::Path;
use Test::TCP;
use Test::Requires qw(LWP::UserAgent);
use HTTP::Request::Common;
use Test::More;

plan skip_all => "TEST_APACHE2 is not set"
    unless $ENV{TEST_APACHE2};

# Note: you need to load 64bit lib to test Apache2 on OS X 10.5 or later

test_tcp(
    client => sub {
        my $port = shift;

        my $ua = LWP::UserAgent->new;
        my $call = sub {
            my $req = shift;
            $req->uri->port($port);
            return $ua->request($req);
        };

        my $res1 = $call->( GET 'http://127.0.0.1/psgi-bin/app.psgi' );
        note $res1->content;
        is $res1->header('X-Script-Name'), '/psgi-bin/app.psgi';
        is $res1->header('X-Path-Info')  , '';

        my $res2 = $call->(
            GET 'http://127.0.0.1/psgi-bin/deep/app.psgi/deeply'
        );
        note $res2->content;
        is $res2->header('X-Script-Name'), '/psgi-bin/deep/app.psgi';
        is $res2->header('X-Path-Info')  , '/deeply';

        my $res3 = $call->( GET 'http://127.0.0.1/psgi-bin/404.psgi' );
        note $res3->content;
        is $res3->code, 404;

        my $res4 = $call->( GET 'http://127.0.0.1/psgi-bin/dead.psgi' );
        note $res4->content;
        is $res4->code, 500;
    },
    server => sub {
        my $port = shift;
        run_httpd($port);
    },
);

done_testing();

sub run_httpd {
    my $port = shift;

    my $tmpdir = $ENV{APACHE2_TMP_DIR} || File::Temp::tempdir( CLEANUP => 1 );

    mkpath( "$tmpdir/psgi-bin" );
    write_file("$tmpdir/psgi-bin/app.psgi", _render_psgi());
    mkpath( "$tmpdir/psgi-bin/deep" );
    write_file("$tmpdir/psgi-bin/deep/app.psgi", _render_psgi());
    write_file("$tmpdir/psgi-bin/dead.psgi", _render_dead_psgi());
    write_file("$tmpdir/httpd.conf", _render_conf($tmpdir, $port));

    exec "httpd -X -D FOREGROUND -f $tmpdir/httpd.conf";
}

sub write_file {
    my($path, $content) = @_;

    open my $out, ">", $path or die "$path: $!";
    print $out $content;
}

sub _render_psgi {
    return <<'EOF';
sub {
    my $env = shift;
    [200, [
        'Content-Type' => 'text/plain',
        'X-Script-Name' => $env->{SCRIPT_NAME},
        'X-Path-Info'   => $env->{PATH_INFO},
    ], ['OK']]
}
EOF
}

sub _render_dead_psgi {
    return <<'EOF';
die 'What's happen?';
EOF
}

sub _render_conf {
    my ($tmpdir, $port) = @_;
    <<"END";
LoadModule perl_module libexec/apache2/mod_perl.so
ServerRoot $tmpdir
DocumentRoot $tmpdir
PidFile $tmpdir/httpd.pid
LockFile $tmpdir/httpd.lock
ErrorLog $tmpdir/error_log
Listen $port

PerlModule Plack::Handler::Apache2::Registry;
<Location /psgi-bin>
SetHandler modperl
PerlHandler Plack::Handler::Apache2::Registry
</Location>
END
}
