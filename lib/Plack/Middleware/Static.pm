package Plack::Middleware::Static;
use strict;
use warnings;
use base qw/Plack::Middleware/;
use File::Spec;
use File::Spec::Unix;
use Path::Class;
use HTTP::Date;
use Cwd ();

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    $args{mime_types} = {
        jpg   => 'image/jpeg',
        jpeg  => 'image/jpeg',
        png   => 'image/png',
        mp3   => 'audio/mpeg',
        '3g2' => 'video/3gpp2',
        '3gp' => 'video/3gpp',
        flv   => 'video/x-flv',
        html  => 'text/html',
        htm   => 'text/html',
        css   => 'text/css',
        csv   => 'text/csv',
        bmp   => 'image/x-bmp',
        ico   => 'image/vnd.microsoft.icon',
        svg   => 'image/svg+xml',
        gif   => 'image/gif',
        gz    => 'application/x-gzip',
        %{ $args{mime_types} || +{} },
    };
    return bless {enable_404_handler => 1, %args}, $class;
}

sub to_app {
    my $self = shift;

    return sub {
        my ($env, @args) = @_;

        my $res = $self->_handle_static($env);
        return $res if $res;

        return $self->app->($env, @args);
    };
}

sub _handle_static {
    my ($self, $env) = @_;
    for my $rule (@{$self->{rules}}) {
        if ($env->{PATH_INFO} =~ $rule->{path}) {
            my $docroot = dir($rule->{root});
            my $file = $docroot->file(File::Spec::Unix->splitpath($env->{PATH_INFO}));
            my $realpath = Cwd::realpath($file->absolute->stringify);

            # error check
            if ($realpath && !$docroot->subsumes($realpath)) {
                return [403, ['Content-Type' => 'text/plain'], ['forbidden']];
            }
            if (!$realpath || !-f $file) {
                return unless $self->{enable_404_handler};
                return [404, ['Content-Type' => 'text/plain'], ['not found']];
            }

            my $content_type = do {
                my $type;
                if ($file =~ /.*\.(\S{1,})$/xms ) {
                    $type = $self->{mime_types}->{$1};
                }
                $type ||= 'text/plain';
                $type;
            };

            my $fh = $file->openr;
            die "Unable to open $file for reading : $!" unless $fh;
            binmode $fh;

            my $stat = $file->stat;
            return [
                200,
                [
                    'Content-Type'   => $content_type,
                    'Content-Length' => $stat->size,
                    'Last-Modified'  => HTTP::Date::time2str( $stat->mtime )
                ],
                $fh
            ];
        }
    }
    return; # fallthrough
}

1;
__END__

=head1 SYNOPSIS

    Plack::Middleware::Static->new(
        rules => [
            +{
                path => qr{^/static/},
                root => './htdocs/',
            }
        ],
        enable_404_handler => 0,
    );

=head1 ATTRIBUTES

=over 4

=item rules

=item enable_404_handler

(default: true)

=back

