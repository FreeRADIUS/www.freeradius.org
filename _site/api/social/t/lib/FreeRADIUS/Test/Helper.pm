package FreeRADIUS::Test::helper;

use strict;
use warnings;
use Import::Into;
use Test::Nginx::Socket 'no_plan';
use Test::More;
use Cwd;
use JSON;

BEGIN {
	# Always need to use an absolute path, else NGINX does silly things
	$ENV{'TEST_NGINX_REPOSITORY_ROOT'} = Cwd::realpath($ENV{'TEST_NGINX_REPOSITORY_ROOT'});

	# Where to find includes...
	$ENV{'LUA_PATH'} = ';;' . $ENV{'TEST_NGINX_REPOSITORY_ROOT'} . '/api/info/?.lua';
	$ENV{'TEST_DATA'} = $ENV{'TEST_NGINX_REPOSITORY_ROOT'} . '/api/info/t/srv';

	#
	#  Perl and Lua don't understand ordered sets of tuples, so we need to get
	#  expected and actual JSON into a canonical form.
	#
	add_response_body_check(sub {
		my ($block, $body, $req_idx, $repeated_req_idx, $dry_run) = @_;
		my $name = $block->name;
		my $decoded;

		# Only evaluate is we have a 'response_body_json_eval' block
		return unless defined($block->response_body_json_eval);

		my $json = JSON->new()->escape_slash([ 1 ])->canonical([ 1 ]);
		my $expected = eval($block->response_body_json_eval) or die("Failed evaluating response_body_json_eval: " . $@);

		eval {
			$decoded = $json->decode($body);
		};
		if ($@) {
			print STDERR "\nJSON was: " . $body . "\n";
			print STDERR "\nParser error was:" . $@ . "\"n";
			return
		}

		if (!is_str($json->encode($decoded), $json->encode($expected),
		       "$name - resp_title (req $repeated_req_idx)")) {
		 	print STDERR "\n" . $json->encode($decoded) . "\n";
		 	print STDERR "\n" . $json->encode($expected) . "\n";
		}
	});
}

sub import {
	my $target = caller;

	strict->import::into($target);
	warnings->import::into($target);
	Test::Nginx::Socket->import::into($target);
	Cwd->import::into($target);
	JSON->import::into($target);
}

1;
