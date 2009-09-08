package TestAppClassExceptionSimpleTest::Exception;
use strict;
use warnings;

sub throw {}

#########

package TestAppClassExceptionSimpleTest;
use strict;
use warnings;

BEGIN { $Catalyst::Exception::CATALYST_EXCEPTION_CLASS = 'TestAppClassExceptionSimpleTest::Exception'; }

use Catalyst;

__PACKAGE__->setup;

1;
