use strict;
use warnings;
use t::Utils;
use Test::More;

plan tests => 12;

use File::Temp qw( tempdir );
use Cwd;

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

do {
    open my $in, '<', \$content;
    my $req = req(
        'psgi.input'   => $in,
        CONTENT_LENGTH => length($content),
        CONTENT_TYPE   => 'multipart/form-data; boundary=----BOUNDARY',
        REQUEST_METHOD => 'POST',
        SCRIPT_NAME    => '/',
        SERVER_PORT    => 80,
    );
    my $tempdir = tempdir( CLEANUP => 1 );
    $req->_body_parser->upload_tmp($tempdir);

    my @undef = $req->upload('undef');
    is @undef, 0;
    my $undef = $req->upload('undef');
    is $undef, undef;

    my @uploads = $req->upload('test_upload_file');
    test_path($uploads[0]->tempname, $tempdir);
    test_path($uploads[1]->tempname, $tempdir);
    test_path($req->upload('test_upload_file4')->tempname, $tempdir);

    like $uploads[0]->slurp, qr|^SHOGUN|;
    like $uploads[1]->slurp, qr|^SHOGUN|;
    is $req->upload('test_upload_file4')->slurp, 'SHOGUN4';

    my $test_upload_file3 = $req->upload('test_upload_file3');
    test_path($test_upload_file3->tempname, $tempdir);
    is $test_upload_file3->slurp, 'SHOGUN3';

    my @test_upload_file6 = $req->upload('test_upload_file6');
    test_path($test_upload_file6[0]->tempname, $tempdir);
    is $test_upload_file6[0]->slurp, 'SHOGUN6';

};

sub test_path {
    my ($lhs, $rhs) = @_;
    is index(Cwd::realpath($lhs), Cwd::realpath($rhs)), 0;
}
