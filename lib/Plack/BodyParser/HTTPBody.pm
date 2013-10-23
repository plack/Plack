package Plack::BodyParser::HTTPBody;
use strict;
use warnings;
use utf8;
use 5.008_001;

use HTTP::Body;
use Hash::MultiValue;
use Plack::Util::Accessor qw(env body);
use Plack::Request::Upload;

sub new {
    my ($class, $env) = @_;

    my $body = HTTP::Body->new($env->{CONTENT_TYPE}, $env->{CONTENT_LENGTH});

    # HTTP::Body will create temporary files in case there was an
    # upload.  Those temporary files can be cleaned up by telling
    # HTTP::Body to do so. It will run the cleanup when the request
    # env is destroyed. That the object will not go out of scope by
    # the end of this sub we will store a reference here.
    $env->{'plack.request.http.body'} = $body;
    $body->cleanup(1);

    bless {body => $body, env => $env}, $class;
}

sub add {
    my $self = shift;
    $self->body->add($_[0]);
}

sub finalize {
    my $self = shift;

    my @uploads = Hash::MultiValue->from_mixed($self->body->upload)->flatten;
    my @obj;
    while (my($k, $v) = splice @uploads, 0, 2) {
        push @obj, $k, $self->_make_upload($v);
    }

    return (
        Hash::MultiValue->from_mixed($self->body->param),
        Hash::MultiValue->new(@obj)
    );
}

sub _make_upload {
    my($self, $upload) = @_;
    my %copy = %$upload;
    $copy{headers} = HTTP::Headers->new(%{$upload->{headers}});
    Plack::Request::Upload->new(%copy);
}

1;
