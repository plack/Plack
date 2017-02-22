use strict;
use warnings;
use Config;
use FindBin;
use Test::More;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;

plan skip_all => "fork not supported on this platform"
  unless $Config::Config{d_fork} || $Config::Config{d_pseudofork} ||
    (($^O eq 'MSWin32' || $^O eq 'NetWare') and
     $Config::Config{useithreads} and
     $Config::Config{ccflags} =~ /-DPERL_IMPLICIT_SYS/);

$Plack::Test::Impl = undef;
my @impl = ('Server', 'MockHTTP');
sub flip_backend {
    push @impl, $Plack::Test::Impl;
    $Plack::Test::Impl = shift @impl;
}

{
    my $handler = builder {
        enable "Plack::Middleware::ErrorDocument",
            404 => "$FindBin::Bin/errors/404.html";

        sub {
            my $env = shift;
            my $status = ($env->{PATH_INFO} =~ m!status/(\d+)!)[0] || 200;
            return sub {
                my $r = shift;
                my $w = $r->([ $status, [ 'Content-Type' => 'text/plain' ]]);
                $w->write("Error: $status\n");
                $w->close;
            };
        };
    };

    test_psgi app => $handler, client => sub {
        my $cb = shift;
        {
            my $res = $cb->(GET "http://localhost/");
            is $res->code, 200;

            $res = $cb->(GET "http://localhost/status/404");
            is $res->code, 404;
            like $res->header('content_type'), qr!text/html!;
            like $res->content, qr/fancy 404/;
        }
    } while flip_backend;
}

{
    my $handler = builder {
        enable "Plack::Middleware::ErrorDocument",
            404 => "/404", subrequest => 1;

        mount '/404' => sub {
            [200, ['Content-Type' => 'text/html'], [<<ERROR]]
a
b
c

This is a fancy 404 page.
ERROR
        };

        mount '/' => sub {
            my $env = shift;
            my $status = ($env->{PATH_INFO} =~ m!status/(\d+)!)[0] || 200;
            return sub {
                my $r = shift;
                my $w = $r->([ $status, [ 'Content-Type' => 'text/plain' ]]);
                $w->write("Error: $status\n");
                $w->close;
            };
        };
    };

    test_psgi app => $handler, client => sub {
        my $cb = shift;
        {
            my $res = $cb->(GET "http://localhost/");
            is $res->code, 200;

            $res = $cb->(GET "http://localhost/status/404");
            is $res->code, 404;
            like $res->header('content_type'), qr!text/html!;
            like $res->content, qr/fancy 404/;
        }
    } while flip_backend;
}

done_testing;
