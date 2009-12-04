package Plack::App::CGIScript;
use strict;
use warnings;
use parent qw/Plack::App::File/;
use CGI::Emulate::PSGI;
use CGI::Compile;

sub serve_path {
    my($self, $env, $file) = @_;

    my $app = $self->{_compiled}->{$file} ||= do {
        my $sub = CGI::Compile->compile($file);
        my $app = CGI::Emulate::PSGI->handler($sub);
    };

    $app->($env);
}

1;

__END__

=head1 NAME

Plack::App::CGIScript - cgi-bin replacement for Plack servers

=head1 SYNOPSIS

  # mount a directory with cgi scripts
  my $app = Plack::App::CGIScript->new(root => "/path/to/cgi-bin")->to_app;
  mount "/cgi-bin" => $app;

=head1 DESCRIPTION

Plack::App::CGIScript allows you to load CGI scripts from a directory
and convert them into a PSGI applicaiton using L<CGI::Emulate::PSGI>
and L<CGI::Compile>.

This would give you the extreme easiness when you have bunch of old
CGI scripts that is loaded using I<cgi-bin> of Apache web server.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plack::App::File> L<CGI::Emulate::PSGI> L<CGI::Compile>
