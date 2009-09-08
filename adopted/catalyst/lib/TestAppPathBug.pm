use strict;
use warnings;

package TestAppPathBug;

use Catalyst;

our $VERSION = '0.01';

__PACKAGE__->config( name => 'TestAppPathBug', root => '/some/dir' );

__PACKAGE__->setup;

sub foo : Path {
    my ( $self, $c ) = @_;
    $c->res->body( 'This is the foo method.' );
}

1;
