use strict;
use warnings;

package output_encoding;

# as these tests serve mostly as a reminder for authors, they can be skipped
use Test::Requires qw( File::Slurp Class::Load );

use Test::More;
use File::Slurp 'read_file';

run();
done_testing;

sub run {
    my $mangler = 'try_mangle.pl';
    $mangler = 't/Plack-Handler/try_mangle.pl' if !-f $mangler;
    
    my $mangle_file = 'mangle_test.txt';
    
    test_handler( 'CGI', $mangler, $mangle_file );
    test_handler( 'FCGI', $mangler, $mangle_file );
    
    return;
}

sub test_handler {
    my ( $handler, $mangler, $mangle_file ) = @_;
    
    system( "$^X $mangler Plack::Handler::$handler > $mangle_file" );
    like read_file( $mangle_file, binmode => ':raw' ), qr/test\ntest/, '\n is not converted';
    unlink $mangle_file;
    
    return;
}
