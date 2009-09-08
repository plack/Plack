package TestApp::Model;
use Moose;
use namespace::clean -except => 'meta';

extends 'Catalyst::Model';

# Test a closure here, r10394 made this blow up when we clone the config down
# onto the subclass..
__PACKAGE__->config(
    escape_flags => {
        'js' => sub { ${ $_[0] } =~ s/\'/\\\'/g; },
    }
);

__PACKAGE__->meta->make_immutable;

