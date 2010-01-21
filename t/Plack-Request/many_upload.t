use strict;
use warnings;
use Test::More;
use Plack::Request;

my $content = qq{------BOUNDARY
Content-Disposition: form-data; name="test_upload_file"; filename="yappo.txt"
Content-Type: text/plain

SHOGUN
------BOUNDARY
Content-Disposition: form-data; name="test_upload_file"; filename="yappo2.txt"
Content-Type: text/plain

SHOGUN2
------BOUNDARY
Content-Disposition: form-data; name="test_upload_file3"; filename="yappo3.txt"
Content-Type: text/plain

SHOGUN3
------BOUNDARY
Content-Disposition: form-data; name="test_upload_file4"; filename="yappo4.txt"
Content-Type: text/plain

SHOGUN4
------BOUNDARY
Content-Disposition: form-data; name="test_upload_file4"; filename="yappo5.txt"
Content-Type: text/plain

SHOGUN4
------BOUNDARY
Content-Disposition: form-data; name="test_upload_file6"; filename="yappo6.txt"
Content-Type: text/plain

SHOGUN6
------BOUNDARY--
};
$content =~ s/\r\n/\n/g;
$content =~ s/\n/\r\n/g;

{
    open my $in, '<', \$content;
    my $req = Plack::Request->new({
        'psgi.input'   => $in,
        CONTENT_LENGTH => length($content),
        CONTENT_TYPE   => 'multipart/form-data; boundary=----BOUNDARY',
        REQUEST_METHOD => 'POST',
        SCRIPT_NAME    => '/',
        SERVER_PORT    => 80,
    });

    my @undef = $req->upload('undef');
    is @undef, 0;
    my $undef = $req->upload('undef');
    is $undef, undef;

    my @uploads = $req->upload('test_upload_file');

    like $uploads[0]->slurp, qr|^SHOGUN|;
    like $uploads[1]->slurp, qr|^SHOGUN|;
    is $req->upload('test_upload_file4')->slurp, 'SHOGUN4';

    my $test_upload_file3 = $req->upload('test_upload_file3');
    is $test_upload_file3->slurp, 'SHOGUN3';

    my @test_upload_file6 = $req->upload('test_upload_file6');
    is $test_upload_file6[0]->slurp, 'SHOGUN6';
}

done_testing;
