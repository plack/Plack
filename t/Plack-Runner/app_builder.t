
use Test::More;
use Plack::Runner;
use File::Path     (qw/make_path remove_tree/);
use Test::Requires (qw/LWP::UserAgent Test::MockObject/);

make_path "tmp/m";

my $app = Test::MockObject->new();
$app->mock(
    to_app => sub {
        eval {
            open my $fh, ">>", "tmp/counter";
            print $fh "1";
            close $fh;
        };
        return sub {
            return [ 200, [], ["Hello"] ];
          }
    }
);

my $runner = Plack::Runner->new;

sub counter_ok {
    my ( $len, $msg ) = @_;
    my $content = "";
    eval {
        open my $fh, "<", "tmp/counter";
        $content = <$fh>;

    };
    is $content , "1" x $len, $msg;
}

$runner->parse_options( -R => 'tmp/m', '-r', -p => 5000 );

my $pid = fork;

if ($pid) {
    my $timeout = 5;
    until ( -f "tmp/counter" ) {
        sleep 1;
        last if $timeout-- == 0;
    }
    if ( $timeout < 0 ) {
        is 1 < 0, "plack up server failed";
        kill 'TERM' => $pid;
    }
    else {
        my $ua  = LWP::UserAgent->new;
        my $res = $ua->get('http://127.0.0.1:5000/');
        ok $res->is_success;
        is $res->code,    200;
        is $res->content, 'Hello';

        counter_ok 1, "app builder not run";

        make_path "tmp/m/a";
        sleep 5;

        counter_ok 2, "app builder run";
        $res = $ua->get('http://127.0.0.1:5000/');
        ok $res->is_success;
        is $res->code,    200;
        is $res->content, 'Hello';

        remove_tree "tmp/m/a";
        sleep 5;

        counter_ok 3, "app builder run again";

        kill 'TERM' => $pid;
    }
}
else {
    $runner->run($app);
    exit 0;
}

remove_tree "tmp";
done_testing;

