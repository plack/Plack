use strict;
use warnings;
use Test::More;
use Test::Requires qw(Apache2::Const);
use Plack;
use Test::TCP;
use LWP::UserAgent;
use FindBin;
use Plack::Test::Suite;

plan skip_all => "TEST_APACHE2 is not set"
    unless $ENV{TEST_APACHE2};

# Note: you need to load 64bit lib to test Apache2 on OS X 10.5 or later

Plack::Test::Suite->run_server_tests(\&run_httpd);
done_testing();

sub run_httpd {
    my $port = shift;

    my $tmpdir = $ENV{APACHE2_TMP_DIR} || File::Temp::tempdir( CLEANUP => 1 );

    write_file("$tmpdir/app.psgi", _render_psgi());
    write_file("$tmpdir/httpd.conf", _render_conf($tmpdir, $port, "$tmpdir/app.psgi"));

    # TODO: wanted to run with -D FOREGROUND but sending TERM/INT to this got the whole .t process to crash. Why?
    system "httpd -f $tmpdir/httpd.conf";

    $SIG{TERM} = sub {
        kill 'INT' => `cat $tmpdir/httpd.pid`;
        exit;
    };

    sleep 60;
    die "server timeout";
}

sub write_file {
    my($path, $content) = @_;

    open my $out, ">", $path or die "$path: $!";
    print $out $content;
}

sub _render_psgi {
    return <<'EOF';
use lib "lib";
use Plack::Test::Suite;

my $handler = sub {
    my $env = shift;
    $Plack::Test::Suite::RAW_TEST[$env->{HTTP_X_PLACK_TEST}][2]->($env);
};
EOF
}

sub _render_conf {
    my ($tmpdir, $port, $psgi_path) = @_;
    <<"END";
LoadModule perl_module libexec/apache2/mod_perl.so
ServerRoot $tmpdir
PidFile $tmpdir/httpd.pid
LockFile $tmpdir/httpd.lock
ErrorLog $tmpdir/error_log
Listen $port

<Location />
SetHandler perl-script
PerlHandler Plack::Server::Apache2
PerlSetVar psgi_app $tmpdir/app.psgi
</Location>
END
}
