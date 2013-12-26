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

}

ok my $psgi_app = sub {
  my $env = shift;

  die MyApp::Exception::Tuple->new(
    404, ['content-type'=>'text/plain'], ['Not Found'])
      if $env->{PATH_INFO} eq '/tuple';

  die MyApp::Exception::CodeRef->new(
    404, ['content-type'=>'text/plain'], ['Not Found'])
      if $env->{PATH_INFO} eq '/coderef';

};

ok $psgi_app = Plack::Middleware::HTTPExceptions->wrap($psgi_app);

test_psgi $psgi_app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/tuple");
    is $res->code, 404;
    is $res->content, 'Not Found';
};

test_psgi $psgi_app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/coderef");
    is $res->code, 404;
    is $res->content, 'Not Found';
};


# need to list the expected test number because of the test case in the
# exception class.
done_testing(8);
