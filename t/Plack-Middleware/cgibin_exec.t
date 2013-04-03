use strict;
use Test::More;
plan skip_all => "release test only" unless $ENV{RELEASE_TESTING};

use Test::Requires { 'CGI::Emulate::PSGI' => 0.10, 'CGI::Compile' => 0.03 };
use Plack::Test;
use HTTP::Request::Common;
use Plack::App::CGIBin;

unless (-e "/usr/bin/python" && -x _) {
    plan skip_all => "You don't have /usr/bin/python";
}

if (`/usr/bin/python --version 2>&1` =~ /^Python 3/) {
    plan skip_all => "This test doesn't support python 3 yet";
}

my $app = Plack::App::CGIBin->new(root => "t/Plack-Middleware/cgi-bin")->to_app;

test_psgi app => $app, client => sub {
    my $cb = shift;

    my $res = $cb->(GET "http://localhost/hello.py?name=foo");
    is $res->code, 200;
    like $res->content, qr/Hello foo/;
    like $res->content, qr/QUERY_STRING is name=foo/;
};

# test that current directory is same the script directory
{
    use File::Basename qw/basename dirname/;
    my $tmp = File::Temp->new(CLEANUP => 1);
    print $tmp <<"...";
#!$^X
use CGI;
use File::Basename qw/dirname/;
use Cwd;

my \$cgi_dir  = Cwd::abs_path( dirname( __FILE__ ) );
my \$exec_dir = Cwd::abs_path( Cwd::getcwd );
my \$result = \$cgi_dir eq \$exec_dir ? "MATCH" : "DIFFERENT";
if (\$result ne "MATCH") {
    \$result .= "\nCGI_DIR: \$cgi_dir\nEXEC_DIR: \$exec_dir\n";
}

my \$q = CGI->new;
print \$q->header(-type => "text/plain"), \$result;
...
    close $tmp;

    chmod(oct("0700"), $tmp->filename) or die "Cannot chmod";

    my $cgi_dir = dirname( $tmp->filename );
    my $cgi_name = basename( $tmp->filename );
    my $app_exec = Plack::App::CGIBin->new(
      root => $cgi_dir,
      exec_cb => sub { 1 } )->to_app;
    test_psgi app => $app_exec, client => sub {
        my $cb = shift;

        my $res = $cb->(GET "http://localhost/$cgi_name?");
        is $res->code, 200;
        is $res->content, "MATCH";
    };

    undef $tmp;
};

done_testing;
