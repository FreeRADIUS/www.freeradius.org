use FindBin qw/$Bin/;
use lib "$Bin/lib";
use FreeRADIUS::Test::helper;

run_tests();

__DATA__

=== TEST 1: Release keyword search regex
Return entries with fields matching the specified pattern

--- main_config
env TEST_DATA;
--- http_config
lua_shared_dict info_api_file_cache 5m;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/branch/[.0-9a-z_-]+/release/$ {
   content_by_lua_file $document_root/api/info/bin/release_index.lua;
}
location ~ ^/api/info/branch/[.0-9a-z_-]+/release/[.0-9a-z_-]+/$ {
   content_by_lua_file $document_root/api/info/bin/release.lua;
}
--- request
GET /api/info/branch/test_branch_a/release/?by_keyword=regex:.*beta&keyword_field=name
--- response_body_json_eval
[
	{
		'name'	=> '1.0.0-beta1',
		'url'	=> '/api/info/branch/test_branch_a/release/1.0.0-beta1/'
	},
	{
		'name'	=> '1.0.0-beta0',
		'url'	=> '/api/info/branch/test_branch_a/release/1.0.0-beta0/'
	}
];
--- error_code: 200
--- no_error_log
[error]

=== TEST 2: Release keyword search, multiple patterns
Return entries with fields matching the specified pattern

--- main_config
env TEST_DATA;
--- http_config
lua_shared_dict info_api_file_cache 5m;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/branch/[.0-9a-z_-]+/release/$ {
   content_by_lua_file $document_root/api/info/bin/release_index.lua;
}
location ~ ^/api/info/branch/[.0-9a-z_-]+/release/[.0-9a-z_-]+/$ {
   content_by_lua_file $document_root/api/info/bin/release.lua;
}
--- request
GET /api/info/branch/test_branch_a/release/?by_keyword=regex:.*beta&keyword_field=name&by_keyword=/api/info/branch/test_branch_a/release/1.0.0-beta1/&keyword_field=url
--- response_body_json_eval
[
	{
		'name'	=> '1.0.0-beta1',
		'url'	=> '/api/info/branch/test_branch_a/release/1.0.0-beta1/'
	}
];
--- error_code: 200
--- no_error_log
[error]

=== TEST 3: Release keyword search, multiple patterns
Return entries with fields matching the specified pattern

--- main_config
env TEST_DATA;
--- http_config
lua_shared_dict info_api_file_cache 5m;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/branch/[.0-9a-z_-]+/release/$ {
   content_by_lua_file $document_root/api/info/bin/release_index.lua;
}
location ~ ^/api/info/branch/[.0-9a-z_-]+/release/[.0-9a-z_-]+/$ {
   content_by_lua_file $document_root/api/info/bin/release.lua;
}
--- request
GET /api/info/branch/test_branch_a/release/?by_keyword=regex:.*beta&keyword_field=name&by_keyword=/api/info/branch/test_branch_a/release/1.0.0-beta1/&keyword_field=name,url
--- response_body_json_eval
[
	{
		'name'	=> '1.0.0-beta1',
		'url'	=> '/api/info/branch/test_branch_a/release/1.0.0-beta1/'
	}
];
--- error_code: 200
--- no_error_log
[error]
