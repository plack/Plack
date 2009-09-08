package TestAppOneView::View::Dummy;

use base 'Catalyst::View';

sub COMPONENT {
    bless {}, 'AClass'
}

package AClass;

use base 'Catalyst::View';

1;
