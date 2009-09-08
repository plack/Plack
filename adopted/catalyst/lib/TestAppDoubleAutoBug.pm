use strict;
use warnings;

package TestAppDoubleAutoBug;

use Catalyst qw/
    Test::Errors
    Test::Headers
    Test::Plugin
/;

our $VERSION = '0.01';

__PACKAGE__->config( name => 'TestAppDoubleAutoBug', root => '/some/dir' );

__PACKAGE__->setup;

sub execute {
    my $c      = shift;
    my $class  = ref( $c->component( $_[0] ) ) || $_[0];
    my $action = $_[1]->reverse();

    my $method;

    if ( $action =~ /->(\w+)$/ ) {
        $method = $1;
    }
    elsif ( $action =~ /\/(\w+)$/ ) {
        $method = $1;
    }
    elsif ( $action =~ /^(\w+)$/ ) {
        $method = $action;
    }

    if ( $class && $method && $method !~ /^_/ ) {
        my $executed = sprintf( "%s->%s", $class, $method );
        my @executed = $c->response->headers->header('X-Catalyst-Executed');
        push @executed, $executed;
        $c->response->headers->header(
            'X-Catalyst-Executed' => join ', ',
            @executed
        );
    }

    return $c->SUPER::execute(@_);
}



sub auto : Private {
    my ( $self, $c ) = @_;
    ++$c->stash->{auto_count};
    return 1;
}

sub default : Private {
    my ( $self, $c ) = @_;
    $c->res->body( sprintf 'default, auto=%d', $c->stash->{auto_count} );
}
