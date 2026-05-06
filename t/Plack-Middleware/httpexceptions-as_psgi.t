use strict;
use warnings;
use Plack::Test;
use HTTP::Request::Common;
use Plack::Middleware::HTTPExceptions;
use Test::More;

{
  package MyApp::Exception::Tuple;

  sub new {
    my ($class, @args) = @_;
    return bless +{res => \@args}, $class;
  }

  sub as_psgi {
    my ($self, $env) = @_;
    Test::More::ok $env && $env->{'psgi.version'}, 
      'has $env and its a psgi $env';
    return $self->{res};
  }

  package MyApp::Exception::CodeRef;

  sub new {
    my ($class, @args) = @_;
    return bless +{res => \@args}, $class;
  }

  sub as_psgi {
    my ($self, $env) = @_;
    Test::More::ok $env && $env->{'psgi.version'}, 
      'has $env and its a psgi $env';

    my ($code, $headers, $body) = @{$self->{res}};

    return sub {
      my $responder = shift;
      $responder->([$code, $headers, $body]);
    };
  }

  package MyApp::Exception::CodeRefWithWrite;

  sub new {
    my ($class, @args) = @_;
    return bless +{res => \@args}, $class;
  }

  sub as_psgi {
    my ($self, $env) = @_;
    Test::More::ok $env && $env->{'psgi.version'}, 
      'has $env and its a psgi $env';

    my ($code, $headers, $body) = @{$self->{res}};

    return sub {
      my $responder = shift;
      my $writer = $responder->([$code, $headers]);
      $writer->write($_) for @$body;
      $writer->close;
    };
  }

}

ok my $psgi_app = sub {
  my $env = shift;

  die MyApp::Exception::Tuple->new(
    404, ['content-type'=>'text/plain'], ['Not Found'])
      if $env->{PATH_INFO} eq '/tuple';

  die MyApp::Exception::CodeRef->new(
    303, ['content-type'=>'text/plain'], ['See Other'])
      if $env->{PATH_INFO} eq '/coderef';

  die MyApp::Exception::CodeRefWithWrite->new(
    400, ['content-type'=>'text/plain'], ['Bad Request'])
      if $env->{PATH_INFO} eq '/coderefwithwrite';

  return [200, ['Content-Type'=>'html/plain'], ['ok']]
      if $env->{PATH_INFO} eq '/ok';
};

ok $psgi_app = Plack::Middleware::HTTPExceptions->wrap($psgi_app);

test_psgi $psgi_app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/tuple");
    is $res->code, 404;
    is $res->content, 'Not Found', 'NOT FOUND';
};

test_psgi $psgi_app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/ok");
    is $res->code, 200;
    is $res->content, 'ok', 'OK';
};

test_psgi $psgi_app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/coderef");
    is $res->code, 303;
    is $res->content, 'See Other', 'SEE OTHER';
};

test_psgi $psgi_app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/coderefwithwrite");
    is $res->code, 400;
    is $res->content, 'Bad Request', 'BAD REQUEST';
};

ok my $psgi_app_delayed = sub {
  my $env = shift;
  return sub {
    my $responder = shift;

    die MyApp::Exception::Tuple->new(
      404, ['content-type'=>'text/plain'], ['Not Found'])
        if $env->{PATH_INFO} eq '/tuple';

    die MyApp::Exception::CodeRef->new(
      303, ['content-type'=>'text/plain'], ['See Other'])
        if $env->{PATH_INFO} eq '/coderef';

    die MyApp::Exception::CodeRefWithWrite->new(
      400, ['content-type'=>'text/plain'], ['Bad Request'])
        if $env->{PATH_INFO} eq '/coderefwithwrite';

    return $responder->
      ([200, ['Content-Type'=>'html/plain'], ['ok']])
        if $env->{PATH_INFO} eq '/ok';
  };
};

ok $psgi_app_delayed = Plack::Middleware::HTTPExceptions->wrap($psgi_app_delayed);

test_psgi $psgi_app_delayed, sub {
    my $cb = shift;
    my $res = $cb->(GET "/tuple");
    is $res->code, 404;
    is $res->content, 'Not Found', 'NOT FOUND';
};

test_psgi $psgi_app_delayed, sub {
    my $cb = shift;
    my $res = $cb->(GET "/ok");
    is $res->code, 200;
    is $res->content, 'ok', 'OK';
};

test_psgi $psgi_app_delayed, sub {
    my $cb = shift;
    my $res = $cb->(GET "/coderef");
    is $res->code, 303;
    is $res->content, 'See Other', 'SEE OTHER';
};

test_psgi $psgi_app_delayed, sub {
    my $cb = shift;
    my $res = $cb->(GET "/coderefwithwrite");
    is $res->code, 400, 'correct 400 code';
    is $res->content, 'Bad Request', 'BAD REQUEST';
};

ok my $psgi_app_delayed_with_write = sub {
  my $env = shift;
  return sub {
    my $responder = shift;
    my $writer = $responder->([200, ['content-type'=>'text/html']]);
    $writer->write('ok');

    die MyApp::Exception::Tuple->new(
      404, ['content-type'=>'text/plain'], ['Not Found'])
        if $env->{PATH_INFO} eq '/tuple';

    die MyApp::Exception::CodeRef->new(
      303, ['content-type'=>'text/plain'], ['See Other'])
        if $env->{PATH_INFO} eq '/coderef';

    die MyApp::Exception::CodeRefWithWrite->new(
      400, ['content-type'=>'text/plain'], ['Bad Request'])
        if $env->{PATH_INFO} eq '/coderefwithwrite';

    return $writer->close if $env->{PATH_INFO} eq '/ok';  };
};

ok $psgi_app_delayed_with_write = Plack::Middleware::HTTPExceptions->wrap($psgi_app_delayed_with_write);

test_psgi $psgi_app_delayed_with_write, sub {
    my $cb = shift;
    my $res = $cb->(GET "/tuple");
    is $res->code, 200;
    is $res->content, 'ok', 'OK';
};

test_psgi $psgi_app_delayed_with_write, sub {
    my $cb = shift;
    my $res = $cb->(GET "/ok");
    is $res->code, 200;
    is $res->content, 'ok', 'OK';
};

test_psgi $psgi_app_delayed_with_write, sub {
    my $cb = shift;
    my $res = $cb->(GET "/coderef");
    is $res->code, 200;
    is $res->content, 'ok', 'OK';
};

test_psgi $psgi_app_delayed_with_write, sub {
    my $cb = shift;
    my $res = $cb->(GET "/coderefwithwrite");
    is $res->code, 200;
    is $res->content, 'ok', 'OK';
};


# need to list the expected test number because of the test case in the
# exception class.
done_testing(36);
