#!/usr/bin/perl
use strict;
use warnings;
use Plack::Loader;
use FindBin;
use Path::Class;
use autodie;
use Test::TCP;
use Getopt::Long;
use Perl6::Say;

my $dot_psgi = 'eg/dot-psgi/Hello.psgi';
my $ab_opt = '-n 100 -c 10 -k';

GetOptions(
    'dot-psgi=s' => \$dot_psgi,
    'ab-opt=s'   => \$ab_opt,
) or die;


&main;exit;

sub main {
    say "dot_psgi: $dot_psgi";
    say "ab_opt: $ab_opt";
    for my $impl_class (qw/AnyEvent Standalone ServerSimple/) {
        run_one($impl_class);
    }
}

sub run_one {
    my $impl_class = shift;
    my $port = Test::TCP::empty_port();
    say "-- impl_class: $impl_class";

    my $pid = fork();
    if ($pid > 0) { # parent
        Test::TCP::wait_port($port);
        say `ab $ab_opt http://127.0.0.1:$port/ | grep 'Requests per '`;
        kill 'TERM' => $pid;
        wait();
    } else {
        my $handler = load_handler(file(Cwd::cwd(), $dot_psgi));
        my $impl = Plack::Loader->load($impl_class, port => $port);
        $impl->run($handler);
        $impl->run_loop if $impl->can('run_loop'); # run event loop
    }
}

#   plackup -i $IMPL  port 8080
#   して ab -n 100 -c 10 -k http://127.0.0.1:8080/

sub load_handler {
    my $file = shift;
    return unless -e $file;
    return do $file;
}

