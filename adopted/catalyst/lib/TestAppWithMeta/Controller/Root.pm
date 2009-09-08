package TestAppWithMeta::Controller::Root;
use base qw/Catalyst::Controller/; # N.B. Do not convert to Moose, so we do not
                                   #      have a metaclass instance!

__PACKAGE__->config( namespace => '' );

no warnings 'redefine';
sub meta { 'fnar' }
use warnings 'redefine';

sub default : Private {
    my ($self, $c) = @_;
    $c->res->body($self->meta);
}

1;

