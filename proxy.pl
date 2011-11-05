#!/usr/bin/env perl

use v5.14;

use Net::Proxy;

sub rewrite {
	my ($dataref, $sock, $connector) = @_;
	Net::Proxy::info('here');
	# rewrite with: http://open.spotify.com/track/5kuzI2Sz53X8P0qztbYzu2
}

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

$proxy->set_verbosity(999);
$proxy->register();

Net::Proxy->mainloop();