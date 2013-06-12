use strict;
use warnings;
use Test::More;
use Plack;
use Test::TCP;
use Test::Requires qw(LWP::UserAgent);
use FindBin;
use File::Path;

use Plack::Test::Suite;

plan skip_all => "TEST_APACHE1 is not set"
    unless $ENV{TEST_APACHE1};

Plack::Test::Suite->run_server_tests(\&run_httpd);
done_testing();

my $log_filename;

sub run_httpd {
    my $port = shift;

    my $tmpdir = $ENV{APACHE1_TMP_DIR} || File::Temp::tempdir( CLEANUP => 1 );

    my $httpd = $ENV{APACHE_BIN} || 'httpd';

    write_file("$tmpdir/app.psgi", _render_psgi());
    write_file("$tmpdir/httpd.conf", _render_conf($tmpdir, $port, "$tmpdir/app.psgi"));
    mkpath( "$tmpdir/conf" );
    write_file("$tmpdir/conf/mime.types", _render_mimetypes());


    $log_filename = "$tmpdir/error_log";
    system ("touch $log_filename");
    link($log_filename, 'err');

    exec "$httpd -X -F -f $tmpdir/httpd.conf" or die "couldn't start httpd : $!\n";
}


sub write_file {
    my($path, $content) = @_;

    open my $out, ">", $path or die "$path: $!";
    print $out $content;
}

sub _render_mimetypes {
    return 'text/html                                       html htm';
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
    my $load_module = ( -f "$tmpdir/libexec/mod_perl.so" ) ? 'LoadModule perl_module libexec/mod_perl.so' : '' ;
    my $conf = <<"END";
$load_module
ServerRoot $tmpdir
ServerName 127.0.0.1
PidFile $tmpdir/httpd.pid
LockFile $tmpdir/httpd.lock
ErrorLog $tmpdir/error_log
Listen $port

<Location />
SetHandler perl-script
PerlHandler Plack::Handler::Apache1
PerlSetVar psgi_app $tmpdir/app.psgi
</Location>
END
    return $conf;
}
