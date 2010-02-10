use Plack::Test;
use Test::More;

use Plack::App::Cascade;
use HTTP::Request::Common;

my $cascade = Plack::App::Cascade->new;
$cascade->add( sub { return sub { my $respond = shift; $respond->([ 404, [], [ "Duh" ] ]) } } );
$cascade->add( sub { return [ 403, [ 'Content-Type', 'text/plain' ], [ "Forbidden" ] ] } );
$cascade->add( sub { return sub {
                         my $w = shift->([ 200, [ 'Content-Type', 'text/plain' ] ]);
                         $w->write("Hello");
                         $w->close;
                     } });

$cascade->catch([ 403, 404 ]);

test_psgi $cascade, sub {
    my $cb = shift;

    my $res = $cb->(GET "http://localhost/");
    is $res->code, 200;
    is $res->content, "Hello";
};

done_testing;
