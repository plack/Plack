#!/usr/bin/env perl
use CGI;
use File::Basename qw/dirname/;
use Cwd;

my $cgi_dir  = Cwd::abs_path( dirname( __FILE__ ) );
my $exec_dir = Cwd::abs_path( Cwd::getcwd );
my $result = $cgi_dir eq $exec_dir ? "MATCH" : "DIFFERENT";
if ($result ne "MATCH") {
    $result .= "\nCGI_DIR: $cgi_dir\nEXEC_DIR: $exec_dir\n";
}

my $q = CGI->new;
print $q->header(-type => "text/plain"), $result;
