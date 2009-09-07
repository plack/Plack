# See t/plugin_new_method_backcompat.t
package Class::Accessor::Fast;
use strict;
use warnings;

sub new {
    my $class = shift;
    return bless $_[0], $class;
}

package TestPluginWithConstructor;
use strict;
use warnings;
use base qw/Class::Accessor::Fast/;

1;

