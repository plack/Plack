use strict;
use Test::More;
use Test::Requires { 'CGI::Emulate::PSGI' => 0.06, 'CGI::Compile' => 0.03 };
use Plack::Test;
use HTTP::Request::Common;
use Plack::App::WrapCGI;
use IO::File;
use File::Temp;
use File::Spec;
use Cwd 'abs_path';

plan skip_all => $^O if $^O eq "MSWin32";

for my $execute (1, 'noexec') {
    note 'Execution model: ' . ($execute eq '1' ? 'fork+exec' : 'fork+noexec');

{
    my $tmp = File::Temp->new(CLEANUP => 1);
    print $tmp <<"...";
#!$^X
use CGI;
my \$q = CGI->new;
print \$q->header, "Hello ", scalar \$q->param('name'), " counter=", ++\$COUNTER;
...
    close $tmp;

    chmod(oct("0700"), $tmp->filename) or die "Cannot chmod";

    my $app_exec = Plack::App::WrapCGI->new(script => "$tmp", execute => $execute)->to_app;
    test_psgi app => $app_exec, client => sub {
        my $cb = shift;

        my $res = $cb->(GET "http://localhost/?name=foo");
        is $res->code, 200;
        is $res->content, "Hello foo counter=1";

        $res = $cb->(POST "http://localhost/", ['name' => 'bar']);
        is $res->code, 200;
        is $res->content, "Hello bar counter=1";
    };

    undef $tmp;
};

{
    my $tmp = File::Temp->new(CLEANUP => 1);
    print $tmp <<"...";
#!$^X
use CGI;
my \$q = CGI->new;
print \$q->header, "Hello " x 10000;
...
    close $tmp;

    chmod(oct("0700"), $tmp->filename) or die "Cannot chmod";

    my $app_exec = Plack::App::WrapCGI->new(script => "$tmp", execute => $execute)->to_app;
    test_psgi app => $app_exec, client => sub {
        my $cb = shift;

        my $res = $cb->(GET "http://localhost/");
        is $res->code, 200;
    };

    undef $tmp;
}

# test that wrapped cgi doesn't wait indefinitely for STDIN
{
    my $tmp = File::Temp->new(CLEANUP => 1);
    print $tmp <<"...";
#!$^X
print "Content-type: text/plain\\n\\nYou said: ";
local \$/;
print <STDIN>;
...
    close $tmp;

    chmod(oct("0700"), $tmp->filename) or die "Cannot chmod";

    my $app_exec = Plack::App::WrapCGI->new(script => "$tmp", execute => $execute)->to_app;
    test_psgi app => $app_exec, client => sub {
        my $cb = shift;

        eval {
            # without the fix $res->content seems to be "alarm\n" which still fails
            local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
            alarm(10);
            my $res = $cb->(GET "http://localhost/?name=foo");
            alarm(0);
            is $res->code, 200;
            is $res->content, "You said: ";

            alarm(10);
            $res = $cb->(POST "http://localhost/", Content => "doing things\nthe hard way");
            alarm(0);
            is $res->code, 200;
            is $res->content, "You said: doing things\nthe hard way";
        };
        if ( $@ ) {
            die unless $@ eq "alarm\n";   # propagate unexpected errors
            ok 0, "request timed out waiting for STDIN";
        }
    };

    undef $tmp;
};

# test that current directory is same the script directory
{
    my $tmp = File::Temp->new(CLEANUP => 1);
    print $tmp <<"...";
#!$^X
use CGI;
use File::Basename qw/dirname/;
use Cwd;

my \$cgi_dir  = Cwd::abs_path( dirname( __FILE__ ) );
my \$exec_dir = Cwd::abs_path( Cwd::getcwd );
my \$result = \$cgi_dir eq \$exec_dir ? "MATCH" : "DIFFERENT";
if (\$result ne "MATCH") {
    \$result .= "\nCGI_DIR: \$cgi_dir\nEXEC_DIR: \$exec_dir\n";
}

my \$q = CGI->new;
print \$q->header(-type => "text/plain"), \$result;
...
    close $tmp;

    chmod(oct("0700"), $tmp->filename) or die "Cannot chmod";

    my $app_exec = Plack::App::WrapCGI->new(script => "$tmp", execute => $execute)->to_app;
    test_psgi app => $app_exec, client => sub {
        my $cb = shift;

        my $res = $cb->(GET "http://localhost/?");
        is $res->code, 200;
        is $res->content, "MATCH";
    };

    undef $tmp;
};

# test that FindBin works if it was used before
{
    use FindBin;
    my $tmp = File::Temp->new(CLEANUP => 1);
    print $tmp <<"...";
#!$^X
use CGI;
use FindBin;

my \$result = "\$FindBin::RealBin\n" . __PACKAGE__ . "\n";

my \$q = CGI->new;
print \$q->header(-type => "text/plain"), \$result;
...
    close $tmp;

    chmod(oct("0700"), $tmp->filename) or die "Cannot chmod";

    my $app_exec = Plack::App::WrapCGI->new(script => "$tmp", execute => $execute)->to_app;
    test_psgi app => $app_exec, client => sub {
        my $cb = shift;

        my $res = $cb->(GET "http://localhost/?");
        is $res->code, 200;
        is $res->content, abs_path(File::Spec->tmpdir) . "\nmain\n";
    };

    undef $tmp;
};

# test that eval { die } works
{
    use FindBin;
    my $tmp = File::Temp->new(CLEANUP => 1);
    print $tmp <<"...";
#!$^X
use CGI;
use FindBin;

eval { die "error message" };
my \$result = \$\@;

my \$q = CGI->new;
print \$q->header(-type => "text/plain"), \$result;
...
    close $tmp;

    chmod(oct("0700"), $tmp->filename) or die "Cannot chmod";

    my $app_exec = Plack::App::WrapCGI->new(script => "$tmp", execute => $execute)->to_app;
    test_psgi app => $app_exec, client => sub {
        my $cb = shift;

        my $res = $cb->(GET "http://localhost/?");
        is $res->code, 200;
        like $res->content, qr{^error message };
    };

    undef $tmp;
};

# Depth of stack
{
    use FindBin;
    my $tmp = File::Temp->new(CLEANUP => 1);
    print $tmp <<"...";
#!$^X
use CGI;
use FindBin;
use Carp;

eval { confess "error message" };
my \$result = \$\@;

my \$q = CGI->new;
print \$q->header(-type => "text/plain"), \$result;
...
    close $tmp;

    chmod(oct("0700"), $tmp->filename) or die "Cannot chmod";

    my $app_exec = Plack::App::WrapCGI->new(script => "$tmp", execute => $execute)->to_app;
    test_psgi app => $app_exec, client => sub {
        my $cb = shift;

        my $res = $cb->(GET "http://localhost/?");
        is $res->code, 200;
	my @lines = split /\n/, $res->content;
	{
	    local $TODO;
	    if ($execute eq 'noexec') {
		$TODO = "Probably there should be a solution using \$Carp::CarpLevel or Sub::Uplevel";
	    }
	    is @lines, 2, 'short stack trace'
		or diag "Stack trace too long: " . join("\n", @lines);
	}
    };

    undef $tmp;
};

}

done_testing;

