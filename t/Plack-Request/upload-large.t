use strict;
use warnings;
use Test::More;
use Plack::Request;
use Plack::Test;
use HTTP::Request::Common;

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

