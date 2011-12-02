use Plack::Test;
use Test::More;

use Plack::App::Cascade;
use HTTP::Request::Common;

my $cascade = Plack::App::Cascade->new;
$cascade->add( sub { return sub { my $respond = shift; $respond->([ 404, [], [ "Duh" ] ]) } } );
$cascade->add( sub { return [ 403, [ 'Content-Type', 'text/plain' ], [ "Forbidden" ] ] } );
$cascade->add( sub { my $env = shift;
                     return sub {
                         my $r = shift;
                         if ($env->{PATH_INFO} eq '/') {
                             my $w = $r->([ 200, [ 'Content-Type', 'text/plain' ] ]);
                             $w->write("Hello");
                             $w->close;
                         } else {
                             $r->([ 404, [ 'Content-Type', 'text/plain' ], [ 'Custom 404 Page' ] ]);
                         }
                     } });

$cascade->catch([ 403, 404 ]);

test_psgi $cascade, sub {
    my $cb = shift;

    my $res = $cb->(GET "http://localhost/");
    is $res->code, 200;
    is $res->content, "Hello";

    $res = $cb->(GET "http://localhost/xyz");
    is $res->code, 404;
    is $res->content, 'Custom 404 Page';
};

done_testing;
