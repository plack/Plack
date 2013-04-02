# NAME

Plack - Perl Superglue for Web frameworks and Web Servers (PSGI toolkit)

# DESCRIPTION

Plack is a set of tools for using the PSGI stack. It contains
middleware components, a reference server and utilities for Web
application frameworks. Plack is like Ruby's Rack or Python's Paste
for WSGI.

See [PSGI](http://search.cpan.org/perldoc?PSGI) for the PSGI specification and [PSGI::FAQ](http://search.cpan.org/perldoc?PSGI::FAQ) to know what
PSGI and Plack are and why we need them.

# MODULES AND UTILITIES

## Plack::Handler

[Plack::Handler](http://search.cpan.org/perldoc?Plack::Handler) and its subclasses contains adapters for web
servers. We have adapters for the built-in standalone web server
[HTTP::Server::PSGI](http://search.cpan.org/perldoc?HTTP::Server::PSGI), [CGI](http://search.cpan.org/perldoc?Plack::Handler::CGI),
[FCGI](http://search.cpan.org/perldoc?Plack::Handler::FCGI), [Apache1](http://search.cpan.org/perldoc?Plack::Handler::Apache1),
[Apache2](http://search.cpan.org/perldoc?Plack::Handler::Apache2) and
[HTTP::Server::Simple](http://search.cpan.org/perldoc?Plack::Handler::HTTP::Server::Simple) included
in the core Plack distribution.

There are also many HTTP server implementations on CPAN that have Plack
handlers.

See [Plack::Handler](http://search.cpan.org/perldoc?Plack::Handler) when writing your own adapters.

## Plack::Loader

[Plack::Loader](http://search.cpan.org/perldoc?Plack::Loader) is a loader to load one [Plack::Handler](http://search.cpan.org/perldoc?Plack::Handler) adapter
and run a PSGI application code reference with it.

## Plack::Util

[Plack::Util](http://search.cpan.org/perldoc?Plack::Util) contains a lot of utility functions for server
implementors as well as middleware authors.

## .psgi files

A PSGI application is a code reference but it's not easy to pass code
reference via the command line or configuration files, so Plack uses a
convention that you need a file named `app.psgi` or similar, which
would be loaded (via perl's core function `do`) to return the PSGI
application code reference.

    # Hello.psgi
    my $app = sub {
        my $env = shift;
        # ...
        return [ $status, $headers, $body ];
    };

If you use a web framework, chances are that they provide a helper
utility to automatically generate these `.psgi` files for you, such
as:

    # MyApp.psgi
    use MyApp;
    my $app = sub { MyApp->run_psgi(@_) };

It's important that the return value of `.psgi` file is the code
reference. See `eg/dot-psgi` directory for more examples of `.psgi`
files.

## plackup, Plack::Runner

[plackup](http://search.cpan.org/perldoc?plackup) is a command line launcher to run PSGI applications from
command line using [Plack::Loader](http://search.cpan.org/perldoc?Plack::Loader) to load PSGI backends. It can be
used to run standalone servers and FastCGI daemon processes. Other
server backends like Apache2 needs a separate configuration but
`.psgi` application file can still be the same.

If you want to write your own frontend that replaces, or adds
functionalities to [plackup](http://search.cpan.org/perldoc?plackup), take a look at the [Plack::Runner](http://search.cpan.org/perldoc?Plack::Runner) module.

## Plack::Middleware

PSGI middleware is a PSGI application that wraps an existing PSGI
application and plays both side of application and servers. From the
servers the wrapped code reference still looks like and behaves
exactly the same as PSGI applications.

[Plack::Middleware](http://search.cpan.org/perldoc?Plack::Middleware) gives you an easy way to wrap PSGI applications
with a clean API, and compatibility with [Plack::Builder](http://search.cpan.org/perldoc?Plack::Builder) DSL.

## Plack::Builder

[Plack::Builder](http://search.cpan.org/perldoc?Plack::Builder) gives you a DSL that you can enable Middleware in
`.psgi` files to wrap existent PSGI applications.

## Plack::Request, Plack::Response

[Plack::Request](http://search.cpan.org/perldoc?Plack::Request) gives you a nice wrapper API around PSGI `$env`
hash to get headers, cookies and query parameters much like
[Apache::Request](http://search.cpan.org/perldoc?Apache::Request) in mod\_perl.

[Plack::Response](http://search.cpan.org/perldoc?Plack::Response) does the same to construct the response array
reference.

## Plack::Test

[Plack::Test](http://search.cpan.org/perldoc?Plack::Test) is a unified interface to test your PSGI application
using standard [HTTP::Request](http://search.cpan.org/perldoc?HTTP::Request) and [HTTP::Response](http://search.cpan.org/perldoc?HTTP::Response) pair with simple
callbacks.

## Plack::Test::Suite

[Plack::Test::Suite](http://search.cpan.org/perldoc?Plack::Test::Suite) is a test suite to test a new PSGI server backend.

# CONTRIBUTING

## Patches and Bug Fixes

Small patches and bug fixes can be either submitted via nopaste on IRC
[irc://irc.perl.org/\#plack](irc://irc.perl.org/\#plack) or [the github issue tracker](http://github.com/plack/Plack/issues).  Forking on
[github](http://github.com/plack/Plack) is another good way if you
intend to make larger fixes.

See also [http://contributing.appspot.com/plack](http://contributing.appspot.com/plack) when you think this
document is terribly outdated.

## Module Namespaces

Modules added to the Plack:: sub-namespaces should be reasonably generic
components which are useful as building blocks and not just simply using
Plack.

Middleware authors are free to use the Plack::Middleware:: namespace for
their middleware components. Middleware must be written in the pipeline
style such that they can chained together with other middleware components.
The Plack::Middleware:: modules in the core distribution are good examples
of such modules. It is recommended that you inherit from [Plack::Middleware](http://search.cpan.org/perldoc?Plack::Middleware)
for these types of modules.

Not all middleware components are wrappers, but instead are more like
endpoints in a middleware chain. These types of components should use the
Plack::App:: namespace. Again, look in the core modules to see excellent
examples of these ([Plack::App::File](http://search.cpan.org/perldoc?Plack::App::File), [Plack::App::Directory](http://search.cpan.org/perldoc?Plack::App::Directory), etc.).
It is recommended that you inherit from [Plack::Component](http://search.cpan.org/perldoc?Plack::Component) for these
types of modules.

__DO NOT USE__ Plack:: namespace to build a new web application or a
framework. It's like naming your application under CGI:: namespace if
it's supposed to run on CGI and that is a really bad choice and
would confuse people badly.

# AUTHOR

Tatsuhiko Miyagawa

# COPYRIGHT

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

Copyright 2009-2013 Tatsuhiko Miyagawa

# CORE DEVELOPERS

Tatsuhiko Miyagawa (miyagawa)

Tokuhiro Matsuno (tokuhirom)

Jesse Luehrs (doy)

Tomas Doran (bobtfish)

Graham Knop (haarg)

# CONTRIBUTORS

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

# SEE ALSO

The [PSGI](http://search.cpan.org/perldoc?PSGI) specification upon which Plack is based.

[http://plackperl.org/](http://plackperl.org/)

The Plack wiki: [https://github.com/plack/Plack/wiki](https://github.com/plack/Plack/wiki)

The Plack FAQ: [https://github.com/plack/Plack/wiki/Faq](https://github.com/plack/Plack/wiki/Faq)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
