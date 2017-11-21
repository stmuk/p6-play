use Cro::HTTP::Log::File;
use Cro::HTTP::Server;
use Cro::HTTP::Router;
use Routes;

my $route = route {
    get -> {
        links();
    }
    get -> $foo {
        links();
    }
}

sub links {

    my $content;

    for 0..(6.rand) {

        my $link = 100.rand.Int;

        $content ~= "<br/><a href='/{$link}'>{$link}</a>";
    }
    content 'text/html', $content;
}

my Cro::Service $http = Cro::HTTP::Server.new(
    http => <1.1>,
    host => %*ENV<HELLO_HOST> ||
        die("Missing HELLO_HOST in environment"),
    port => %*ENV<HELLO_PORT> ||
        die("Missing HELLO_PORT in environment"),
    application => $route,
    after => [
        Cro::HTTP::Log::File.new(logs => $*OUT, errors => $*ERR)
    ]
);
$http.start;
say "Listening at http://%*ENV<HELLO_HOST>:%*ENV<HELLO_PORT>";
react {
    whenever signal(SIGINT) {
        say "Shutting down...";
        $http.stop;
        done;
    }
}
