use strict;
use Cwd;
use File::Spec;
use File::Temp;
use Test::Requires qw(LWP::UserAgent);
use Test::More;
use Test::TCP qw(empty_port);

plan skip_all => "release test only" unless $ENV{RELEASE_TESTING};

sub write_file($$){
    my ( $path, $content ) = @_;
    open my $out, '>', $path or die "$path: $!";
    print $out $content;
    close $out;
}

my $tmpdir  = File::Temp::tempdir( CLEANUP => 1 );
my $psgi_file = File::Spec->catfile($tmpdir, 'app.psgi');
write_file $psgi_file, qq/my \$app = sub {return [200, [], ["hello world"]]}\n/;

my $port = empty_port();
my $pid = fork;
if ($pid == 0) {
    close STDERR;
    exec($^X, '-Ilib', 'script/plackup', '-p', $port, '--path', '/app/', '-a', $psgi_file) or die $@;
} else {
    $SIG{INT} = 'IGNORE';
    sleep 1;
    my $ua = LWP::UserAgent->new;
    my $res =  $ua->get("http://localhost:$port/");
    is $res->code, 404;
    $res =  $ua->get("http://localhost:$port/app/");
    is $res->code, 200;
    is $res->content, 'hello world';
    kill 'INT', $pid;
    wait;
}

done_testing;

