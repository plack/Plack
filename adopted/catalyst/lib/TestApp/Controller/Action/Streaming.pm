package TestApp::Controller::Action::Streaming;

use strict;
use base 'TestApp::Controller::Action';

sub streaming : Global {
    my ( $self, $c ) = @_;
    for my $line ( split "\n", <<'EOF' ) {
foo
bar
baz
EOF
        $c->res->write("$line\n");
    }
}

sub body : Local {
    my ( $self, $c ) = @_;

    my $file = "$FindBin::Bin/../lib/TestApp/Controller/Action/Streaming.pm";
    my $fh = IO::File->new( $file, 'r' );
    if ( defined $fh ) {
        $c->res->body( $fh );
    }
    else {
        $c->res->body( "Unable to read $file" );
    }
}

sub body_large : Local {
    my ($self, $c) = @_;

    # more than one write with the default chunksize
    my $size = 128 * 1024;

    my $data = "\0" x $size;
    open my $fh, '<', \$data;
    $c->res->content_length($size);
    $c->res->body($fh);
}

1;
