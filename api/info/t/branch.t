use FindBin qw/$Bin/;
use lib "$Bin/lib";
use FreeRADIUS::Test::Common;

run_tests();

__DATA__

=== TEST 1: Branch
Verify we get info about a branch and all releases on that branch

--- main_config
env TEST_DATA;
--- http_config
lua_shared_dict info_api_file_cache 5m;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/branch/[.0-9a-z_-]+/$ {
   content_by_lua_file $document_root/api/info/bin/branch.lua;
}
--- request
GET /api/info/branch/test_branch_a/
--- response_body_json_eval
{
	'name'		=> 'test_branch_a',
	'description'	=> 'test_branch_a description',
	'status'	=> 'end of life',
	'release'	=> {
		'url'	=> '/api/info/branch/test_branch_a/release/'
	}
};
--- error_code: 200
--- no_error_log
[error]
