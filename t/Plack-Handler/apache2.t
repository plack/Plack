use strict;
use warnings;
use Test::More;
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

    exec "httpd -X -D FOREGROUND -f $tmpdir/httpd.conf";
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

Plack::Test::Suite->test_app_handler;
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

<Perl>
use Plack::Handler::Apache2;
Plack::Handler::Apache2->preload("$tmpdir/app.psgi");
</Perl>

<Location />
SetHandler perl-script
PerlHandler Plack::Handler::Apache2
PerlSetVar psgi_app $tmpdir/app.psgi
</Location>
END
}
