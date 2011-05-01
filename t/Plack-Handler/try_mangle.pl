use strict;
use warnings;

package try_mangle;

use Class::Load 'load_class';

my $module = $ARGV[0];

$module ||= 'Plack::Handler::CGI';

load_class( $module );

my $res = [200,[],["test\ntest"]];
$module->_handle_response( $res );

exit;
