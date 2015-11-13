package Plack::Request::Body;
use strict;
use warnings;
use Hash::MultiValue;

sub new {
    my($class, $content_type, $length) = @_;

    if ($content_type =~ m!^application/x-www-form-urlencoded\b!i) {
        $class = "$class\::UrlEncoded";
    } elsif ($content_type =~ m!^multipart/form-data\b!i) {
        $class = "$class\::MultiPart";
    }

    my $self = bless {
        content_type => $content_type,
        length       => $length,
        param_list   => [],
        upload_list  => [],
    }, $class;

    $self->init;
    $self;
}

sub init { }
sub read { }
sub finish { }

sub parameters {
    my $self = shift;
    Hash::MultiValue->new(@{ $self->{param_list} });
}

sub uploads {
    my $self = shift;
    Hash::MultiValue->new(@{ $self->{upload_list} });
}

package Plack::Request::Body::UrlEncoded;
our @ISA = qw( Plack::Request::Body );
use URL::Encode ();

sub init {
    my $self = shift;
    $self->{buffer} = '';
}

sub read {
    my($self, $chunk) = @_;
    $self->{buffer} .= $chunk;
}

sub finish {
    my $self = shift;
    $self->{param_list} = URL::Encode::url_params_flat($self->{buffer});
}

package Plack::Request::Body::MultiPart;
our @ISA = qw( Plack::Request::Body );
use Carp ();
use File::Temp ();
use HTTP::MultiPartParser ();
use Plack::Request::Upload;

our $HeaderToken = qr/[^][\x00-\x1f\x7f()<>@,;:\\"\/?={} \t]+/;

sub init {
    my $self = shift;

    $self->{content_type} =~ /boundary=\"?([^\";]+)\"?/
      or Carp::croak("Invalid boundary in content_type: $self->{content_type}");

    $self->{parser} = HTTP::MultiPartParser->new(
        boundary => $1,
        on_header => sub { $self->on_header(@_) },
        on_body   => sub { $self->on_body(@_); if ($_[1]) { $self->on_complete(@_) } },
    );

    $self->{tempdir} = File::Temp->newdir;
}

sub on_header {
    my($self, $headers) = @_;

    $self->{headers} = HTTP::Headers::Fast->new;

    for my $header (@$headers) {
        $header =~ s/^($HeaderToken):[\t ]*//;
        $self->{headers}->push_header($1 => $header);
    }

    $self->{fh} = File::Temp->new(UNLINK => 0, DIR => $self->{tempdir});
}

sub on_body {
    my($self, $chunk) = @_;
    $self->{fh}->write($chunk);
}

sub on_complete {
    my $self = shift;

    $self->{fh}->seek(0, 0);

    my $disposition = $self->{headers}->header('Content-Disposition');
    my ($name)      = $disposition =~ / name="?([^\";]+)"?/;
    my ($filename)  = $disposition =~ / filename="?([^\"]*)"?/;

    my $index = $#{$self->{upload_list}} + 1;
    $name = "upload$index" unless defined $name;

    my $upload = Plack::Request::Upload->new(
        filename => $filename,
        headers => $self->{headers},
        size => -s $self->{fh},
        tempname => $self->{fh}->filename,
    );

    push @{$self->{upload_list}}, $name => $upload;
    
    delete $self->{headers};
    delete $self->{fh};

    1;
}

sub read {
    my($self, $chunk) = @_;
    $self->{parser}->parse($chunk);
}

sub finish {
    my $self = shift;
    $self->{parser}->finish;

    # break circular refs
    delete $self->{parser};

    1;
}

1;
