for my $s ( qw( Apache1 Apache2 CGI FCGI Standalone ) ) {
    open my $fh, ">$s.pm";
    print $fh <<EOF;
package Plack::Server::$s;
use strict;
use parent qw(Plack::Handler::$s);

sub new {
    my \$class = shift;
    warn "Use of \$class is deprecated. Use Plack::Handler::$s or Plack::Loader to upgrade.";
    \$class->SUPER::new(\@_);
}

1;

__END__

=head1 NAME

Plack::Server::$s - DEPRECATED

=head1 DESCRIPTION

B<This module is deprecated>. See L<Plack::Handler::$s>.

=cut
EOF
}


