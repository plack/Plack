package MyComponent;
use strict;
use warnings;
use Config;
use Test::More;
use Scalar::Util qw/weaken/;
use parent 'Plack::Component';

plan skip_all => "fork not supported on this platform"
  unless $Config::Config{d_fork} || $Config::Config{d_pseudofork} ||
    (($^O eq 'MSWin32' || $^O eq 'NetWare') and
     $Config::Config{useithreads} and
     $Config::Config{ccflags} =~ /-DPERL_IMPLICIT_SYS/);

sub call {
    my $self = shift;
    my $env = shift;

    if( $env->{PATH_INFO} eq '/run_response_cb' ){
        my $my;

        # Record $res and $cb
        $self->{res} = [200, ['Content-Type' => 'text/plain'], ['OK']];
        $self->{cb}  = sub { $my }; # Contain $my to be regard as a closure.

        return $self->response_cb($self->{res}, $self->{cb});
    }else{
        # Decrease REFCNT
        weaken $self->{res};
        weaken $self->{cb};

        # Check if references are released.
        return [ 200, [
            'Content-Type' => 'text/plain',
            'X-Res-Freed'  => ! $self->{res},
            'X-Cb-Freed'   => ! $self->{cb},
        ], ['HELLO'] ];
    }
}


package main;
use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
$Plack::Test::Impl = "Server";
local $ENV{PLACK_SERVER} = "HTTP::Server::PSGI";

my $app = MyComponent->new;
test_psgi( $app->to_app, sub {
    my $cb = shift;
    $cb->(GET '/run_response_cb');

    my $req = $cb->(GET '/check');
    ok $req->header('X-Res-Freed'), '$res has been released.';
    ok $req->header('X-Cb-Freed') , '$cb has been released.';
} );

done_testing;
