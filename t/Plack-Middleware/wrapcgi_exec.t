use strict;
use Test::More;
use Test::Requires { 'CGI::Emulate::PSGI' => 0.06, 'CGI::Compile' => 0.03 };
use Plack::Test;
use HTTP::Request::Common;
use Plack::App::WrapCGI;
use IO::File;
use File::Temp;

plan skip_all => $^O if $^O eq "MSWin32";

my $tmp = File::Temp->new(CLEANUP => 1);
print $tmp <<"...";
#!$^X
use CGI;
my \$q = CGI->new;
print \$q->header, "Hello " x 10000;
...
close $tmp;

chmod(oct("0700"), $tmp->filename) or die "Cannot chmod";

my $app_exec = Plack::App::WrapCGI->new(script => "$tmp", execute => 1)->to_app;
test_psgi app => $app_exec, client => sub {
    my $cb = shift;

    my $res = $cb->(GET "http://localhost/");
    is $res->code, 200;
    };

undef $tmp;

done_testing;

