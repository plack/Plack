use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Response;

sub res {
    my $res = Plack::Response->new;
    my %v = @_;
    while (my($k, $v) = each %v) {
        $res->$k($v);
    }
    $res;
}

my $res = res(
    status => 200,
    body => 'hello',
);


test_psgi $res->to_app(), sub {
    my $cb = shift;

    my $res = $cb->(GET "/");
    is $res->code, 200, 'response code';
    is $res->content, 'hello', 'content';
};

done_testing;
