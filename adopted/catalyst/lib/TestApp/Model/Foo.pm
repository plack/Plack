package TestApp::Model::Foo;

use strict;
use warnings;

use base qw/ Catalyst::Model /;

__PACKAGE__->config( 'quux' => 'chunkybacon' );

sub model_foo_method { 1 }

sub model_quux_method { shift->{quux} }

package TestApp::Model::Foo::Bar;
sub model_foo_bar_method_from_foo { 1 }

package TestApp::Model::Foo;
sub bar { "TestApp::Model::Foo::Bar" }

1;
