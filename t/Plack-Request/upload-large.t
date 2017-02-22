use strict;
use warnings;
use Config;
use Test::More;
use Plack::Request;
use Plack::Test;
use HTTP::Request::Common;

plan skip_all => "fork not supported on this platform"
  unless $Config::Config{d_fork} || $Config::Config{d_pseudofork} ||
    (($^O eq 'MSWin32' || $^O eq 'NetWare') and
     $Config::Config{useithreads} and
     $Config::Config{ccflags} =~ /-DPERL_IMPLICIT_SYS/);

my $file = "share/baybridge.jpg";

my @backends = qw( Server MockHTTP );
sub flip_backend { $Plack::Test::Impl = shift @backends }

local $ENV{PLACK_SERVER} = "HTTP::Server::PSGI";

my $app = sub {
    my $req = Plack::Request->new(shift);
    is $req->uploads->{image}->size, -s $file;
    is $req->uploads->{image}->content_type, 'image/jpeg';
    is $req->uploads->{image}->basename, 'baybridge.jpg';
    $req->new_response(200)->finalize;
};

test_psgi $app, sub {
    my $cb = shift;
    $cb->(POST "/", Content_Type => 'form-data', Content => [
             image => [ $file ],
         ]);
} while flip_backend;

done_testing;

