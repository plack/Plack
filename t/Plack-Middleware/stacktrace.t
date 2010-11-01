use strict;
use warnings;
use Test::More;
use Plack::Middleware::StackTrace;
use Plack::Test;
use HTTP::Request::Common;

my $traceapp = Plack::Middleware::StackTrace->wrap(sub { die "orz" }, no_print_errors => 1);
my $app = sub {
    my $env = shift;
    my $ret = $traceapp->($env);
    like $env->{'plack.stacktrace.text'}, qr/orz/;
    return $ret;
};

test_psgi $app, sub {
    my $cb = shift;

    my $req = GET "/";
    $req->header(Accept => "text/html,*/*");
    my $res = $cb->($req);

    ok $res->is_error;
    is_deeply [ $res->content_type ], [ 'text/html', 'charset=utf-8' ];
    like $res->content, qr/orz/;
};


$traceapp = Plack::Middleware::StackTrace->wrap(
    sub { die My::Fault->new("orz") },
    no_print_errors => 1
);
$app = sub {
    my $env = shift;
    my $ret = $traceapp->($env);
    like $env->{'plack.stacktrace.text'}, qr/\Aorz/;
    like $env->{'plack.stacktrace.text'}, qr/My::Fault::new/;
    return $ret;
};

test_psgi $app, sub {
    my $cb = shift;

    my $req = GET "/";
    $req->header(Accept => "text/html,*/*");
    my $res = $cb->($req);

    ok $res->is_error;
    is_deeply [ $res->content_type ], [ 'text/html', 'charset=utf-8' ];
    like $res->content, qr/orz/;
};

done_testing;

EXCEPTION: {
    package My::Fault;
    use overload '""' => 'as_string';
    sub as_string { shift->{msg} };
    sub new { bless { msg => $_[1], trace => Devel::StackTrace->new } }
    sub trace { shift->{trace}}
}
