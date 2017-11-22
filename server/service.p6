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
    host => %*ENV<SERVER_HOST> ||
        die("Missing SERVER_HOST in environment"),
    port => %*ENV<SERVER_PORT> ||
        die("Missing SERVER_PORT in environment"),
    application => $route,
    after => [
        Cro::HTTP::Log::File.new(logs => $*OUT, errors => $*ERR)
    ]
);
$http.start;
say "Listening at http://%*ENV<SERVER_HOST>:%*ENV<SERVER_PORT>";
react {
    whenever signal(SIGINT) {
        say "Shutting down...";
        $http.stop;
        done;
    }
}
