use strict;
use warnings;
use Test::More;
use Plack::Request;
use Plack::Test;
use HTTP::Request::Common;

my $file = "share/kyoto.jpg";

my @backends = qw( Server MockHTTP );
sub flip_backend { $Plack::Test::Impl = shift @backends }

my $app = sub {
    my $req = Plack::Request->new(shift);
    is $req->uploads->{image}->size, -s $file;
    $req->new_response(200)->finalize;
};

test_psgi $app, sub {
    my $cb = shift;
    $cb->(POST "/", Content_Type => 'form-data', Content => [
             image => [ $file ],
         ]);
} while flip_backend;

done_testing;

