use FindBin qw/$Bin/;
use lib "$Bin/lib";
use FreeRADIUS::Test::Common;

run_tests();

__DATA__

=== TEST 1: Branch index
Verify we get entries representing all the branches in the branch directory

--- main_config
env TEST_DATA;
--- http_config
lua_shared_dict info_api_file_cache 5m;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/branch/$ {
   content_by_lua_file $document_root/api/info/bin/branch_index.lua;
}
--- request
GET /api/info/branch/?order_by=name
--- response_body_json_eval
[
	{
		'name'  => 'test_branch_a',
		'url'   => '/api/info/branch/test_branch_a/'
	},
	{
		'name'  => 'test_branch_b',
		'url'   => '/api/info/branch/test_branch_b/'
	}
];
--- error_code: 200
--- no_error_log
[error]
