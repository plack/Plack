package t::PerlbalUtils;
use strict;
use warnings;
use File::Temp ();
use FindBin;
use Test::More;
use IO::Socket;
use base qw/Exporter/;

our @EXPORT = qw/ run_perlbal /;

sub run_perlbal {
    my($port, $num) = @_;

    chomp(my $perlbal_bin = `which perlbal`);

    plan skip_all => 'perlbal not found in PATH'
        unless $perlbal_bin && -x $perlbal_bin;

    my $tmpdir = File::Temp::tempdir( CLEANUP => 1 );

    write_file("$tmpdir/app.psgi", _render_psgi($num));
    write_file("$tmpdir/perlbal.conf", _render_conf($tmpdir, $port, "$tmpdir/app.psgi"));

    my $pid = open my $perlbal, "$perlbal_bin -c $tmpdir/perlbal.conf 2>&1 |"
        or die "Unable to spawn perlbal: $!";

    $SIG{TERM} = sub {
        kill 'INT', $pid;
        close $perlbal;
        exit;
    };

    sleep 60; # waiting tests.
    die "server timeout";
}

sub write_file {
    my($path, $content) = @_;

    open my $out, ">", $path or die "$path: $!";
    print $out $content;
}

sub _render_psgi {
    my $num = shift;
    return <<"EOF";
use lib "lib";
use Plack::Test;

my \$handler = \$Plack::Test::RAW_HANDLERS[$num];
EOF
}

sub _render_conf {
    my ($tmpdir, $port, $psgi_path) = @_;
    <<"END";
LOAD PSGI

CREATE SERVICE psgi
  SET listen        = 127.0.0.1:$port
  SET role          = web_server
  SET plugins       = psgi
  PSGI_APP          = $psgi_path
ENABLE psgi

# always good to keep an internal management port open:
CREATE SERVICE mgmt
  SET role   = management
  SET listen = 127.0.0.1:60000
ENABLE mgmt


END
}

1;
