use strict;
use Plack::Test;
use Test::Requires qw(Log::Log4perl);

use Test::More;
use Plack::Middleware::Log4perl;
use HTTP::Request::Common;

my $test_file = "t/Plack-Middleware/log4perl.log";

my $conf = <<CONF;
log4perl.logger.plack.test = INFO, Logfile
log4perl.appender.Logfile = Log::Log4perl::Appender::File
log4perl.appender.Logfile.filename = $test_file
log4perl.appender.Logfile.layout   = Log::Log4perl::Layout::SimpleLayout
CONF

Log::Log4perl::init(\$conf);

my $app = sub {
    my $env = shift;
    $env->{'psgix.logger'}->({ level => "debug", message => "This is debug" });
    $env->{'psgix.logger'}->({ level => "info", message => "This is info" });
    return [ 200, [], [] ];
};

$app = Plack::Middleware::Log4perl->wrap($app, category => 'plack.test');

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/");

    my $log = do {
        open my $fh, "<", $test_file;
        join '', <$fh>;
    };

    like $log, qr/INFO - This is info/;
    unlike $log, qr/debug/;
};

END { unlink $test_file }

done_testing;
