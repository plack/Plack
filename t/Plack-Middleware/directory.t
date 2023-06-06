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

        open my $fh, ">", "share/#foo" or die $!;
        close $fh;

        # URI-escape
        my $res = $cb->(GET "http://localhost/");
        my($ct, $charset) = $res->content_type;
        ok $res->content =~ m{/%23foo};

        $res = $cb->(GET "/..");
        is $res->code, 403;

        $res = $cb->(GET "/..%00foo");
        is $res->code, 400;

        $res = $cb->(GET "/..%5cfoo");
        is $res->code, 403;

        $res = $cb->(GET "/");
        like $res->content, qr/Index of \//;

        unlink "share/#foo";

    SKIP: {
            skip "Filenames can't end with . on windows", 2 if $^O eq "MSWin32";

            mkdir "share/stuff..", 0777;
            open my $out, ">", "share/stuff../Hello.txt" or die $!;
            print $out "Hello\n";
            close $out;

            $res = $cb->(GET "/stuff../Hello.txt");
            is $res->code, 200;
            is $res->content, "Hello\n";

            unlink "share/stuff../Hello.txt";
            rmdir "share/stuff..";
        }
    },
    app => $handler,
);

test_psgi %test;

$handler = Plack::App::Directory->new({ root => 'share', dir_index => 'index.html' });

%test = (
    client => sub {
        my $cb  = shift;

        open my $fh, ">", "share/index.html" or die $!;
        print $fh "<html>\n</html>";
        close $fh;

        my $res = $cb->(GET "/");
        is $res->code, 200;
        is $res->content, "<html>\n</html>";

        unlink "share/index.html";

    },
    app => $handler,
);

test_psgi %test;

done_testing;
