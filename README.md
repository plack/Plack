# NAME

Plack - Perl Superglue for Web frameworks and Web Servers (PSGI toolkit)

# DESCRIPTION

Plack is a set of tools for using the PSGI stack. It contains
middleware components, a reference server and utilities for Web
application frameworks. Plack is like Ruby's Rack or Python's Paste
for WSGI.

See [PSGI](https://metacpan.org/pod/PSGI) for the PSGI specification and [PSGI::FAQ](https://metacpan.org/pod/PSGI%3A%3AFAQ) to know what
PSGI and Plack are and why we need them.

# MODULES AND UTILITIES

## Plack::Handler

[Plack::Handler](https://metacpan.org/pod/Plack%3A%3AHandler) and its subclasses contains adapters for web
servers. We have adapters for the built-in standalone web server
[HTTP::Server::PSGI](https://metacpan.org/pod/HTTP%3A%3AServer%3A%3APSGI), [CGI](https://metacpan.org/pod/Plack%3A%3AHandler%3A%3ACGI),
[FCGI](https://metacpan.org/pod/Plack%3A%3AHandler%3A%3AFCGI), [Apache1](https://metacpan.org/pod/Plack%3A%3AHandler%3A%3AApache1),
[Apache2](https://metacpan.org/pod/Plack%3A%3AHandler%3A%3AApache2) and
[HTTP::Server::Simple](https://metacpan.org/pod/Plack%3A%3AHandler%3A%3AHTTP%3A%3AServer%3A%3ASimple) included
in the core Plack distribution.

There are also many HTTP server implementations on CPAN that have Plack
handlers.

See [Plack::Handler](https://metacpan.org/pod/Plack%3A%3AHandler) when writing your own adapters.

## Plack::Loader

[Plack::Loader](https://metacpan.org/pod/Plack%3A%3ALoader) is a loader to load one [Plack::Handler](https://metacpan.org/pod/Plack%3A%3AHandler) adapter
and run a PSGI application code reference with it.

## Plack::Util

[Plack::Util](https://metacpan.org/pod/Plack%3A%3AUtil) contains a lot of utility functions for server
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

[plackup](https://metacpan.org/pod/plackup) is a command line launcher to run PSGI applications from
command line using [Plack::Loader](https://metacpan.org/pod/Plack%3A%3ALoader) to load PSGI backends. It can be
used to run standalone servers and FastCGI daemon processes. Other
server backends like Apache2 needs a separate configuration but
`.psgi` application file can still be the same.

If you want to write your own frontend that replaces, or adds
functionalities to [plackup](https://metacpan.org/pod/plackup), take a look at the [Plack::Runner](https://metacpan.org/pod/Plack%3A%3ARunner) module.

## Plack::Middleware

PSGI middleware is a PSGI application that wraps an existing PSGI
application and plays both side of application and servers. From the
servers the wrapped code reference still looks like and behaves
exactly the same as PSGI applications.

[Plack::Middleware](https://metacpan.org/pod/Plack%3A%3AMiddleware) gives you an easy way to wrap PSGI applications
with a clean API, and compatibility with [Plack::Builder](https://metacpan.org/pod/Plack%3A%3ABuilder) DSL.

## Plack::Builder

[Plack::Builder](https://metacpan.org/pod/Plack%3A%3ABuilder) gives you a DSL that you can enable Middleware in
`.psgi` files to wrap existent PSGI applications.

## Plack::Request, Plack::Response

[Plack::Request](https://metacpan.org/pod/Plack%3A%3ARequest) gives you a nice wrapper API around PSGI `$env`
hash to get headers, cookies and query parameters much like
[Apache::Request](https://metacpan.org/pod/Apache%3A%3ARequest) in mod\_perl.

[Plack::Response](https://metacpan.org/pod/Plack%3A%3AResponse) does the same to construct the response array
reference.

## Plack::Test

[Plack::Test](https://metacpan.org/pod/Plack%3A%3ATest) is a unified interface to test your PSGI application
using standard [HTTP::Request](https://metacpan.org/pod/HTTP%3A%3ARequest) and [HTTP::Response](https://metacpan.org/pod/HTTP%3A%3AResponse) pair with simple
callbacks.

## Plack::Test::Suite

[Plack::Test::Suite](https://metacpan.org/pod/Plack%3A%3ATest%3A%3ASuite) is a test suite to test a new PSGI server backend.

# CONTRIBUTING

## Patches and Bug Fixes

Small patches and bug fixes can be either submitted via nopaste on IRC
[irc://irc.perl.org/#plack](irc://irc.perl.org/#plack) or [the github issue
tracker](http://github.com/plack/Plack/issues).  Forking on
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
of such modules. It is recommended that you inherit from [Plack::Middleware](https://metacpan.org/pod/Plack%3A%3AMiddleware)
for these types of modules.

Not all middleware components are wrappers, but instead are more like
endpoints in a middleware chain. These types of components should use the
Plack::App:: namespace. Again, look in the core modules to see excellent
examples of these ([Plack::App::File](https://metacpan.org/pod/Plack%3A%3AApp%3A%3AFile), [Plack::App::Directory](https://metacpan.org/pod/Plack%3A%3AApp%3A%3ADirectory), etc.).
It is recommended that you inherit from [Plack::Component](https://metacpan.org/pod/Plack%3A%3AComponent) for these
types of modules.

**DO NOT USE** Plack:: namespace to build a new web application or a
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

The [PSGI](https://metacpan.org/pod/PSGI) specification upon which Plack is based.

[http://plackperl.org/](http://plackperl.org/)

The Plack wiki: [https://github.com/plack/Plack/wiki](https://github.com/plack/Plack/wiki)

The Plack FAQ: [https://github.com/plack/Plack/wiki/Faq](https://github.com/plack/Plack/wiki/Faq)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
