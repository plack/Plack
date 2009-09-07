use strict;
use warnings;

package TestAppStats;

use Catalyst qw/
    -Stats=1
/;

our $VERSION = '0.01';
our @log_messages;

__PACKAGE__->config( name => 'TestAppStats', root => '/some/dir' );

__PACKAGE__->log(TestAppStats::Log->new);

__PACKAGE__->setup;

# Return log messages from previous request
sub default : Private {
    my ( $self, $c ) = @_;
    $c->stats->profile("test");
    $c->res->body(join("\n", @log_messages));
    @log_messages = ();
}

package TestAppStats::Log;
use base qw/Catalyst::Log/;

sub info { push(@log_messages, @_); }
sub debug { push(@log_messages, @_); }
