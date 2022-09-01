package Plack::Middleware::IIS6ScriptNameFix;

use strict;
use parent 'Plack::Middleware';
use Plack::Util::Accessor qw(force);

sub call {
    my($self, $env) = @_;

    if ($self->force || ($env->{SERVER_SOFTWARE} && $env->{SERVER_SOFTWARE} =~ /IIS\/[6-9]\.[0-9]/)) {
        my @script_name = split(m!/!, $env->{PATH_INFO});
        my @path_translated = split(m!/|\\\\?!, $env->{PATH_TRANSLATED});
        my @path_info;

        while ($script_name[$#script_name] eq $path_translated[$#path_translated]) {
            pop(@path_translated);
            unshift(@path_info, pop(@script_name));
        }

        unshift(@path_info, '', '');

        $env->{PATH_INFO} = join('/', @path_info);
        $env->{SCRIPT_NAME} = join('/', @script_name);
    }

    return $self->app->($env);
}

1;

__END__

=head1 NAME

Plack::Middleware::IIS6ScriptNameFix - fixes wrong SCRIPT_NAME and PATH_INFO that IIS6 sets

=head1 SYNOPSIS

  # in your app.psgi
  use Plack::Builder;

  builder {
    enable "IIS6ScriptNameFix";
    $app;
  };

  # Or from the command line
  plackup -s FCGI -e 'enable "IIS6ScriptNameFix"' /path/to/app.psgi

=head1 DESCRIPTION

This middleware fixes wrong C<SCRIPT_NAME> and C<PATH_INFO> set by IIS6.

=head1 OPTIONS

=over 4

=item force

By default, this middleware checks if C<SERVER_SOFTWARE> PSGI environment
matches what Microsoft IIS server 6-9 would set for FastCGI. By setting C<force>
to true (1), this middleware always applies the fix, regardless of the
C<SERVER_SOFTWARE> string.

Use this option if the environment is broken similar to IIS, or if the IIS is
updated and the regular expression in this module doesn't match any more
e.g. you're running IIS 10.

=back

=head1 AUTHORS

Florian Ragwitz

=cut
