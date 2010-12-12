use strict;
use warnings;
use Test::Requires qw(Module::Refresh);
use File::Spec;
use File::Temp;
use HTTP::Request::Common;
use Plack::Middleware::Refresh;
use Plack::Test;
use Test::More;

sub write_file($$){
    my ( $path, $content ) = @_;
    open my $out, '>', $path or die "$path: $!";
    print $out $content;
}

my $tmpdir  = File::Temp::tempdir( CLEANUP => 1 );
my $pm_file = File::Spec->catfile($tmpdir, 'SomeModule.pm');
write_file $pm_file, qq/sub SomeModule::hello {'...'}; 1;\n/;

# Load SomeModule
unshift @INC, $tmpdir;
require SomeModule;

my $app = Plack::Middleware::Refresh->wrap(sub {
    [200, [ 'X-SomeModule' => SomeModule->hello ], ["OK\n"]]
}, cooldown => 0 );

test_psgi $app, sub {
    my $cb = shift;

    # Change SomeModule before the server gets requests.
    sleep 1;
    write_file $pm_file, qq/sub SomeModule::hello {'Hi.'}; 1;\n/;
    my $res = $cb->(GET "/");
    is $res->header('X-SomeModule'), 'Hi.';

    # Change again.
    sleep 1;
    write_file $pm_file, qq/sub SomeModule::hello {'Good-bye.'}; 1;\n/;
    $res = $cb->(GET "/");
    is $res->header('X-SomeModule'), 'Good-bye.';
};

done_testing;
