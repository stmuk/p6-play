use v6;

use HTML::Parser::XML;
use XML::Document;
use HTTP::UserAgent;

my %url_seen;

our $ua =  HTTP::UserAgent.new;
my $t0 = DateTime.now.Instant;

my @promises;

sub MAIN(:$domain="http://localhost:20000") {

    my @urls=($domain);

    loop {

        # fire off promises if still work in urls array
        while ( @urls ) {
            my $url = @urls.shift;
            my $p = Promise.start({&extract($domain,$url)});
            @promises.push($p);
        }

        # process promises and add work to urls array if needed
        for @promises -> $pw {
            next unless $pw.status ~~ Kept;
            # lists don't flatten in perl6 XXX
            my @furls =  |$pw.result; 
            # delete old promises so we don't process again
            @promises.shift if @furls;

            for @furls {
                @urls.push( $_) unless %url_seen{$_};
                %url_seen{$_}++; 
            }
        }
        # terminate if no work and all promises completed
        if @urls.elems == 0 && Promise.allof(@promises) {
            last;
        }

    }

    say DateTime.now.Instant-$t0 ~ " sec(s)";

}

sub get($uri) {
    my $response = $ua.get($uri);
    return $response.content;
}

sub extract($domain,$uri) {
    dd $uri;
    my $page = get($uri);
    my $p = HTML::Parser::XML.new;
    my XML::Document $doc = $p.parse($page);
    # URLs to crawl 
    my %todo;
    my @anchors = $doc.elements(:TAG<a>, :RECURSE);
    for @anchors -> $anchor {
        next unless $anchor<href>.defined;
        my $href =  $anchor<href>.Str;

        # Convert rel to abs urls
        if $href.starts-with('/') {
            $href = $domain ~ $href;
        }

        # unique list from page
        if $href.starts-with($domain) {
            %todo{$href}++;
        }
    }
    my @urls = %todo.keys;

    return @urls;

}

