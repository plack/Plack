package Plack;

use strict;
use warnings;
use 5.008_001;
our $VERSION = '1.0033';

1;
__END__

=head1 NAME

Plack - Perl Superglue for Web frameworks and Web Servers (PSGI toolkit)

=head1 DESCRIPTION

Plack is a set of tools for using the PSGI stack. It contains
middleware components, a reference server and utilities for Web
application frameworks. Plack is like Ruby's Rack or Python's Paste
for WSGI.

See L<PSGI> for the PSGI specification and L<PSGI::FAQ> to know what
PSGI and Plack are and why we need them.

=head1 MODULES AND UTILITIES

=head2 Plack::Handler

L<Plack::Handler> and its subclasses contains adapters for web
servers. We have adapters for the built-in standalone web server
L<HTTP::Server::PSGI>, L<CGI|Plack::Handler::CGI>,
L<FCGI|Plack::Handler::FCGI>, L<Apache1|Plack::Handler::Apache1>,
L<Apache2|Plack::Handler::Apache2> and
L<HTTP::Server::Simple|Plack::Handler::HTTP::Server::Simple> included
in the core Plack distribution.

There are also many HTTP server implementations on CPAN that have Plack
handlers.

See L<Plack::Handler> when writing your own adapters.

=head2 Plack::Loader

L<Plack::Loader> is a loader to load one L<Plack::Handler> adapter
and run a PSGI application code reference with it.

=head2 Plack::Util

L<Plack::Util> contains a lot of utility functions for server
implementors as well as middleware authors.

=head2 .psgi files

A PSGI application is a code reference but it's not easy to pass code
reference via the command line or configuration files, so Plack uses a
convention that you need a file named C<app.psgi> or similar, which
would be loaded (via perl's core function C<do>) to return the PSGI
application code reference.

  # Hello.psgi
  my $app = sub {
      my $env = shift;
      # ...
      return [ $status, $headers, $body ];
  };

If you use a web framework, chances are that they provide a helper
utility to automatically generate these C<.psgi> files for you, such
as:

  # MyApp.psgi
  use MyApp;
  my $app = sub { MyApp->run_psgi(@_) };

It's important that the return value of C<.psgi> file is the code
reference. See C<eg/dot-psgi> directory for more examples of C<.psgi>
files.

=head2 plackup, Plack::Runner

L<plackup> is a command line launcher to run PSGI applications from
command line using L<Plack::Loader> to load PSGI backends. It can be
used to run standalone servers and FastCGI daemon processes. Other
server backends like Apache2 needs a separate configuration but
C<.psgi> application file can still be the same.

If you want to write your own frontend that replaces, or adds
functionalities to L<plackup>, take a look at the L<Plack::Runner> module.

=head2 Plack::Middleware

PSGI middleware is a PSGI application that wraps an existing PSGI
application and plays both side of application and servers. From the
servers the wrapped code reference still looks like and behaves
exactly the same as PSGI applications.

L<Plack::Middleware> gives you an easy way to wrap PSGI applications
with a clean API, and compatibility with L<Plack::Builder> DSL.

=head2 Plack::Builder

L<Plack::Builder> gives you a DSL that you can enable Middleware in
C<.psgi> files to wrap existent PSGI applications.

=head2 Plack::Request, Plack::Response

L<Plack::Request> gives you a nice wrapper API around PSGI C<$env>
hash to get headers, cookies and query parameters much like
L<Apache::Request> in mod_perl.

L<Plack::Response> does the same to construct the response array
reference.

=head2 Plack::Test

L<Plack::Test> is a unified interface to test your PSGI application
using standard L<HTTP::Request> and L<HTTP::Response> pair with simple
callbacks.

=head2 Plack::Test::Suite

L<Plack::Test::Suite> is a test suite to test a new PSGI server backend.

=head1 CONTRIBUTING

=head2 Patches and Bug Fixes

Small patches and bug fixes can be either submitted via nopaste on IRC
L<irc://irc.perl.org/#plack> or L<the github issue
tracker|http://github.com/plack/Plack/issues>.  Forking on
L<github|http://github.com/plack/Plack> is another good way if you
intend to make larger fixes.

See also L<http://contributing.appspot.com/plack> when you think this
document is terribly outdated.

=head2 Module Namespaces

Modules added to the Plack:: sub-namespaces should be reasonably generic
components which are useful as building blocks and not just simply using
Plack.

Middleware authors are free to use the Plack::Middleware:: namespace for
their middleware components. Middleware must be written in the pipeline
style such that they can chained together with other middleware components.
The Plack::Middleware:: modules in the core distribution are good examples
of such modules. It is recommended that you inherit from L<Plack::Middleware>
for these types of modules.

Not all middleware components are wrappers, but instead are more like
endpoints in a middleware chain. These types of components should use the
Plack::App:: namespace. Again, look in the core modules to see excellent
examples of these (L<Plack::App::File>, L<Plack::App::Directory>, etc.).
It is recommended that you inherit from L<Plack::Component> for these
types of modules.

B<DO NOT USE> Plack:: namespace to build a new web application or a
framework. It's like naming your application under CGI:: namespace if
it's supposed to run on CGI and that is a really bad choice and
would confuse people badly.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 COPYRIGHT

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

Copyright 2009-2013 Tatsuhiko Miyagawa

=head1 CORE DEVELOPERS

Tatsuhiko Miyagawa (miyagawa)

Tokuhiro Matsuno (tokuhirom)

Jesse Luehrs (doy)

Tomas Doran (bobtfish)

Graham Knop (haarg)

=head1 CONTRIBUTORS

Yuval Kogman (nothingmuch)

Kazuhiro Osawa (Yappo)

Kazuho Oku

Florian Ragwitz (rafl)

Chia-liang Kao (clkao)

Masahiro Honma (hiratara)

Daisuke Murase (typester)

John Beppu

Matt S Trout (mst)

Shawn M Moore (Sartak)

Stevan Little

Hans Dieter Pearcey (confound)

mala

Mark Stosberg

Aaron Trevena

=head1 SEE ALSO

The L<PSGI> specification upon which Plack is based.

L<http://plackperl.org/>

The Plack wiki: L<https://github.com/plack/Plack/wiki>

The Plack FAQ: L<https://github.com/plack/Plack/wiki/Faq>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
