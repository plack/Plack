use strict;
use Test::More;
use Test::Requires { 'CGI::Emulate::PSGI' => 0, 'CGI::Compile' => 0.03 };
use Plack::Test;
use HTTP::Request::Common;
use Plack::App::WrapCGI;
use IO::File;
use File::Temp;

my $app = Plack::App::WrapCGI->new(script => "t/Plack-Middleware/cgi-bin/hello.cgi")->to_app;

test_psgi app => $app, client => sub {
    my $cb = shift;

    my $res = $cb->(GET "http://localhost/?name=foo");
    is $res->code, 200;
    is $res->content, "Hello foo counter=1";

    $res = $cb->(GET "http://localhost/?name=bar");
    is $res->code, 200;
    is $res->content, "Hello bar counter=2";
};

{
    my $tmp = File::Temp->new(CLEANUP => 1);
    print $tmp <<"...";
#!$^X
use CGI;
my \$q = CGI->new;
print \$q->header, "Hello ", \$q->param('name'), " counter=", ++\$COUNTER;
...
    close $tmp;

    chmod(oct("0700"), $tmp->filename) or die "Cannot chmod";

    my $app_exec = Plack::App::WrapCGI->new(script => "$tmp", execute => 1)->to_app;
    test_psgi app => $app_exec, client => sub {
        my $cb = shift;

        my $res = $cb->(GET "http://localhost/?name=foo");
        is $res->code, 200;
        is $res->content, "Hello foo counter=1";

        $res = $cb->(POST "http://localhost/", ['name' => 'bar']);
        is $res->code, 200;
        is $res->content, "Hello bar counter=1";
    };

    undef $tmp;
};


done_testing;
