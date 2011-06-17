use strict;
use warnings;

package output_encoding;

use Test::More;

run();
done_testing;

sub read_file {
    open my $fh, "<", shift;
    binmode $fh;
    return join '', <$fh>;
}

sub run {
    my $mangler = 'try_mangle.pl';
    $mangler = 't/Plack-Handler/try_mangle.pl' if !-f $mangler;

    my $mangle_file = 'mangle_test.txt';

    test_handler( 'CGI', $mangler, $mangle_file );
#    test_handler( 'FCGI', $mangler, $mangle_file );

    return;
}

sub test_handler {
    my ( $handler, $mangler, $mangle_file ) = @_;

    system( "$^X $mangler Plack::Handler::$handler > $mangle_file" );
    like read_file( $mangle_file ), qr/test\ntest/, '\n is not converted';
    unlink $mangle_file;

    return;
}
