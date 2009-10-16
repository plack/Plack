use AnyEvent::Twitter::Stream;
use Encode;

my $app = sub {
    my $env = shift;

    my $keyword = $env->{PATH_INFO};
    $keyword =~ s!^/!!;

    my $cv = AE::cv;

    # track keywords
    my $guard = AnyEvent::Twitter::Stream->new(
        username => $ENV{TWITTER_USERNAME},
        password => $ENV{TWITTER_PASSWORD},
        method   => "filter",
        track    => $keyword || "twitter",
        on_tweet => sub { $cv->send(@_) },
    );

    return sub {
        my $respond = shift;
        my $w = $respond->([ 200, ['Content-Type' => 'text/plain'] ]);
        my $cb; $cb = sub {
            my $tweet = shift->recv;
            $w->write(Encode::encode_utf8($tweet->{text}) . "\n");
            $cv = AE::cv;
            $cv->cb($cb);
        };
        $cv->cb($cb);
    };
};
