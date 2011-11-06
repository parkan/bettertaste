#!/usr/bin/env perl

use v5.14;

use HTTP::Proxy;
use HTTP::Proxy::BodyFilter::simple;
use JSON::XS;
use Data::Dumper;

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

$proxy->start;