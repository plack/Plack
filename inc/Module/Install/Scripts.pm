package Module::Install::Scripts;

use strict 'vars';
use Module::Install::Base;

use vars qw{$VERSION $ISCORE @ISA};
BEGIN {
	$VERSION = '0.80';
	$ISCORE  = 1;
	@ISA     = qw{Module::Install::Base};
}

sub install_script {
	my $self = shift;
	my $args = $self->makemaker_args;
	my $exe  = $args->{EXE_FILES} ||= [];
        foreach ( @_ ) {
		if ( -f $_ ) {
			push @$exe, $_;
		} elsif ( -d 'script' and -f "script/$_" ) {
			push @$exe, "script/$_";
		} else {
			die("Cannot find script '$_'");
		}
	}
}

1;

