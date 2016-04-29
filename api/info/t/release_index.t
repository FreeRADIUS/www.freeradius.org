use FindBin qw/$Bin/;
use lib "$Bin/lib";
use FreeRADIUS::Test::helper;

run_tests();

__DATA__

=== TEST 1: Release index
Verify we get info about releases on a branch

--- main_config
env TEST_DATA;
--- http_config
lua_shared_dict info_api_file_cache 5m;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/branch/[.0-9a-z_-]+/release/$ {
   content_by_lua_file $document_root/api/info/bin/release_index.lua;
}
--- request
GET /api/info/branch/test_branch_a/release/
--- response_body_json_eval
[
	{
		'name'	=> '1.0.0-pre0',
		'url'	=> '/api/info/branch/test_branch_a/release/1.0.0-pre0/'
	},
	{
		'name'	=> '1.0.0-beta1',
		'url'	=> '/api/info/branch/test_branch_a/release/1.0.0-beta1/'
	},
	{
		'name'	=> '1.0.0-beta0',
		'url'	=> '/api/info/branch/test_branch_a/release/1.0.0-beta0/'
	},
	{
		'name'	=> '1.0.0-alpha0',
		'url'	=> '/api/info/branch/test_branch_a/release/1.0.0-alpha0/'
	},
	{
		'name'	=> '0.0.2',
		'url'	=> '/api/info/branch/test_branch_a/release/0.0.2/'
	},
	{
		'name'	=> '0.0.1',
		'url'	=> '/api/info/branch/test_branch_a/release/0.0.1/'
	}
];
--- error_code: 200
--- no_error_log
[error]
