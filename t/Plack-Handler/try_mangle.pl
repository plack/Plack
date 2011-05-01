use strict;
use warnings;

package try_mangle;

my $module = $ARGV[0];

$module ||= 'Plack::Handler::CGI';

eval "require $module";

my $res = [200,[],["test\ntest"]];
$module->_handle_response( $res );

exit;
