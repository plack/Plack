package Plack::Handler::Apache2::Registry;
use strict;
use warnings;
use Try::Tiny;
use Apache2::Const;
use Apache2::Log;
use parent qw/Plack::Handler::Apache2/;

sub handler {
    my $class = __PACKAGE__;
    my ($r) = @_;

    return try {
        my $app = $class->load_app( $r->filename );
        $class->call_app( $r, $app );
    }catch{
        if(/no such file/i){
            $r->log_error( $_ );
            return Apache2::Const::NOT_FOUND;
        }else{
            $r->log_error( $_ );
            return Apache2::Const::SERVER_ERROR;
        }
    };
}

# Overriding
sub fixup_path {
    my ($class, $r, $env) = @_;
    $env->{PATH_INFO} =~ s{^$env->{SCRIPT_NAME}}{};
}

1;

__END__

=head1 NAME

Plack::Handler::Apache2::Registry - Runs .psgi files.

=head1 SYNOPSIS

  PerlModule Plack::Handler::Apache2::Registry;
  <Location /psgi-bin>
  SetHandler modperl
  PerlHandler Plack::Handler::Apache2::Registry
  </Location>

=head1 DESCRIPTION

This is a handler module to run any *.psgi files with mod_perl2,
just like ModPerl::Registry.

=head1 AUTHOR

Masahiro Honma E<lt>hiratara@cpan.orgE<gt>

=head1 SEE ALSO

L<Plack::Handler::Apache2>

=cut

