use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use HTTP::Response;
use Plack::Test;
use Plack::App::Directory;

my $handler = Plack::App::Directory->new({ root => 'share' });


my %test = (
    client => sub {
        my $cb  = shift;

        {
            # URI-escape
            my $res = $cb->(GET "http://localhost/");
            my($ct, $charset) = $res->content_type;
            ok $res->content =~ m{/%23foo};
        }
},
    app => $handler,
);

test_psgi %test;

done_testing;
