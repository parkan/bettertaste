#!/usr/bin/env perl

use v5.14;

=no
sub rewrite {
	my ($dataref, $sock, $connector) = @_;
	Net::Proxy::info('here');
	print Dumper(@_);
	# rewrite with: http://open.spotify.com/track/5kuzI2Sz53X8P0qztbYzu2
}
my $proxy = HTTP::Proxy->new( port => 4879 );
$proxy->logmask('ALL');

#$proxy->push_filter( request => \&rewrite );
$proxy->push_filter(
	method => 'CONNECT',
	request => HTTP::Proxy::BodyFilter::simple->new( sub{
		my ( $self, $dataref, $message, $protocol, $buffer ) = @_; 
		print Dumper( $dataref, $message, $protocol, $buffer );
	})
);
=cut

use Getopt::Long;

my $rewrite = '';
my $stalk = '';

my $opts = GetOptions(
	'rewrite=s' => \$rewrite,
	'stalk=s' => \$stalk # NOT IMPLEMENTED
);

package Spotify::Hijack {

use HTTP::Server::Simple::CGI;
use base qw(HTTP::Server::Simple::CGI);

use LWP::UserAgent;
use Crypt::SSLeay;
use JSON::XS;
use IO::Socket::SSL;
use DateTime;

use Data::Dumper;

my $is_evil = 0;

sub setup {
	my ($self, %params) = @_;

	if($params{'method'} eq 'CONNECT' && !$is_evil){
		$is_evil = 1;	
		print "HTTP/1.0 200 Connection established\r\n";
		print "Proxy-agent: Netscape-Proxy/1.1\r\n";
		warn "Got CONNECT, rewrites engaged\n";

		$self->rewrite();
	}
}

sub valid_http_method {
	my ($self, $method) = @_;
	return $method =~ m/POST|GET|CONNECT/;
}

sub set_rewrite {
	my ($self, $rewrite) = @_;
	$self->{'rewrite'} = $rewrite;
}

sub rewrite {
	my $self = shift;
	my $ua = LWP::UserAgent->new;
	$ua->agent('Spotify-Win32/0.71/40800213'); # just for fun

	my $time = DateTime->now()->strftime('%a, %d %b %Y %H:%M:%S %z');

	my $url = "https://graph.facebook.com/me/music.listens";

	my $req = {
		song => $self->{'rewrite'},
		expires_in => 300,
		created_time => '2011-11-06T02:40:26Z',
		access_token => 'AAAAAKLSe4lIBANO8Bl07IG0dNjsHMRP2nSjh6tJt29vxa6JkoL8mA7KuiZA9jLa0DdGwctNhZAgxePaD6WEZBLYhhx3H6UZD'
	};

	warn "REWRITING to:\n";
	warn Dumper($req);

	my $res = $ua->post($url, $req);

	warn Dumper($res);
	warn "SUBMITTED TO graph.facebook.com:443!\n";
}

sub accept_hook {
        my $self = shift;

        # initial CONNECT w/o SSL
        if(1 || !$is_evil){
        	#warn "PLAINTEXT";
        	return;
        }

        # SSL facebook impersonation!
        my $fh = $self->stdio_handle;

        $self->SUPER::accept_hook(@_);

        warn "EVIL: setting up SSL\n";

        my $newfh =
        IO::Socket::SSL->start_SSL( $fh, 
            SSL_server => 1,
            SSL_use_cert => 1,
            SSL_cert_file => 'newcert.pem',
            SSL_key_file => 'newkey.pem',
        )
        or warn "problem setting up SSL socket: " . IO::Socket::SSL::errstr();

        $self->stdio_handle($newfh) if $newfh;
}

}

=nope

=wrong
my $proxy = Net::Proxy->new({
	in => {
		type => 'ssl',
	    host => '0.0.0.0',
	    port => 4879,
	    SSL_key_file => 'dsakey.pem',
	    SSL_cert_file => 'certs/facebook.pem',
	    start_cleartext => 1,
	    hook => \&rewrite
	},
	out => {
		host => 'graph.facebook.com',
		port => 443,
		type => 'tcp',
		port => '80'
	}
});

$proxy->set_verbosity(4);
$proxy->register();
=cut

#$proxy->start;

my $port = 4879;
my $server = Spotify::Hijack->new($port);
$server->set_rewrite($rewrite);
$server->run();
say "Spotify hijacker running at port $port";
