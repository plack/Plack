#!/usr/bin/env perl
use strict;
use warnings;
use autodie;
use FCGI::Client;
use Plack::Loader;
use Getopt::Long;
use Pod::Usage;
use File::Temp ();
use IO::Socket::UNIX;
use Benchmark ':all';

my %opts = (app => "eg/dot-psgi/Hello.psgi");
GetOptions(\%opts, "app=s", "impl=s", "help");

pod2usage(0) if $opts{help};

my $fname = File::Temp::tmpnam();
my $env = +{ };
my $content = '';

my $pid = fork();
if ($pid > 0) {
    timethis(
        10000 => sub {
            my $sock = IO::Socket::UNIX->new( Peer => $fname ) or die $!;
            my $conn = FCGI::Client::Connection->new( sock => $sock );
            my ( $stdout, $stderr ) = $conn->request( $env, $content );
        }
    );
    kill 9, $pid;
    wait;
} else {
    my $sock = IO::Socket::UNIX->new( Local => $fname, Listen => 10 )
      or die $!;
    open *STDIN, '>&', $sock;    # dup
    my $handler = Plack::Util::load_psgi($opts{app});
    my $impl = Plack::Loader->load('FCGI');
    $impl->run($handler);
    die 'should not reach here';
}
