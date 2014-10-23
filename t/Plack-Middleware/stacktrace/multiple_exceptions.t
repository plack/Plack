use strict;
use warnings;
use Test::More;
use Plack::Middleware::StackTrace;
use Plack::Test;
use HTTP::Request::Common;

{
    # Simple exception object
    package Plack::Middleware::StackTrace::Exception;

    use overload '""' => sub { $_[0]->{message} };

    sub new {
        my ($class, $message) = @_;
        return bless { message => $message }, $class;
    }
}

# Tracks how often the destructor was called
my $dtor_count;

{
    # A class similar to DBIx::Class::Storage::TxnScopeGuard where the
    # destructor might throw and catch another exception.
    package Plack::Middleware::StackTrace::Guard;
    use Try::Tiny;

    sub new {
        my ($class, $exception) = @_;
        return bless { exception => $exception }, $class;
    }

    sub DESTROY {
        my $self = shift;
        ++$dtor_count;
        try { die $self->{exception}; };
    }
}

sub test_dtor_exception {
    my ($orig_exception, $dtor_exception) = @_;

    my $dtor_exception_app = sub {
        my $guard = Plack::Middleware::StackTrace::Guard->new($dtor_exception);
        die $orig_exception;
    };

    my $trace_app = Plack::Middleware::StackTrace->wrap($dtor_exception_app,
        no_print_errors => 1,
    );

    test_psgi $trace_app, sub {
        my $cb = shift;

        $dtor_count = 0;
        my $req = GET "/";
        my $res = $cb->($req);

        is $res->code, 500, "Status code is 500";
        like $res->content, qr/^\Q$orig_exception\E at /,
             "Original exception returned";
        is $dtor_count, 1, "Destructor called only once";
    };
}

test_dtor_exception("urz", "orz");
test_dtor_exception(
    Plack::Middleware::StackTrace::Exception->new("urz"),
    Plack::Middleware::StackTrace::Exception->new("orz"),
);

{
    # A middleware that rethrows exceptions
    package Plack::Middleware::StackTrace::Rethrow;
    use parent qw(Plack::Middleware);
    use Try::Tiny;

    sub call {
        my ($self, $env) = @_;
        try {
            $self->app->($env);
        } catch {
            die $_;
        };
    }
}

# This sub is expected to appear in the stack trace.
sub fizzle {
    my $exception = shift;
    die $exception;
}

sub test_rethrown_exception {
    my $exception = shift;

    my $die_app = sub {
        fizzle($exception);
    };

    my $rethrow_app = Plack::Middleware::StackTrace::Rethrow->wrap($die_app);

    my $trace_app = Plack::Middleware::StackTrace->wrap($rethrow_app,
        no_print_errors => 1,
    );

    test_psgi $trace_app, sub {
        my $cb = shift;

        my $req = GET "/";
        my $res = $cb->($req);

        is $res->code, 500, "Status code is 500";
        like $res->content, qr/\bfizzle\b/, "Original stack trace returned";
    };
}

test_rethrown_exception("orz");
test_rethrown_exception(Plack::Middleware::StackTrace::Exception->new("orz"));

done_testing;

