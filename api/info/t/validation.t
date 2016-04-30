use FindBin qw/$Bin/;
use lib "$Bin/lib";
use FreeRADIUS::Test::helper;

run_tests();

__DATA__

=== TEST 1: Junk args branch_index
Verify junk args are detected and raise an error

--- main_config
env TEST_DATA;
--- http_config
lua_shared_dict info_api_file_cache 5m;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/branch/[.0-9a-z_-]+/release/[.0-9a-z_-]+/$ {
   content_by_lua_file $document_root/api/info/bin/release.lua;
}
--- request
GET /api/info/branch/test_branch_a/release/0.0.1/?foo=bar
--- response_body_json_eval
{
	"error" => "get argument foo=bar not recognised"
}
--- error_code: 400
--- no_error_log
[error]

=== TEST 2: Junk args branch
Verify junk args are detected and raise an error

--- main_config
env TEST_DATA;
--- http_config
lua_shared_dict info_api_file_cache 5m;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/branch/[.0-9a-z_-]+/$ {
   content_by_lua_file $document_root/api/info/bin/release.lua;
}
--- request
GET /api/info/branch/test_branch_a/?foo=bar
--- response_body_json_eval
{
	"error" => "get argument foo=bar not recognised"
}
--- error_code: 400
--- no_error_log
[error]

=== TEST 3: Junk args component_index
Verify junk args are detected and raise an error

--- main_config
env TEST_DATA;
--- http_config
lua_shared_dict info_api_file_cache 5m;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/component/$ {
   content_by_lua_file $document_root/api/info/bin/release.lua;
}
--- request
GET /api/info/component/?foo=bar
--- response_body_json_eval
{
	"error" => "get argument foo=bar not recognised"
}
--- error_code: 400
--- no_error_log
[error]

=== TEST 4: Junk args component
Verify junk args are detected and raise an error

--- main_config
env TEST_DATA;
--- http_config
lua_shared_dict info_api_file_cache 5m;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/component/[.0-9a-z_-]+/$ {
   content_by_lua_file $document_root/api/info/bin/release.lua;
}
--- request
GET /api/info/component/rlm_test_a/?foo=bar
--- response_body_json_eval
{
	"error" => "get argument foo=bar not recognised"
}
--- error_code: 400
--- no_error_log
[error]

=== TEST 5: Junk args release_index
Verify junk args are detected and raise an error

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
GET /api/info/branch/test_branch_a/release/?foo=bar
--- response_body_json_eval
{
	"error" => "get argument foo=bar not recognised"
}
--- error_code: 400
--- no_error_log
[error]

=== TEST 6: Junk args release
Verify junk args are detected and raise an error

--- main_config
env TEST_DATA;
--- http_config
lua_shared_dict info_api_file_cache 5m;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/branch/[.0-9a-z_-]+/release/[.0-9a-z_-]+/$ {
   content_by_lua_file $document_root/api/info/bin/release.lua;
}
--- request
GET /api/info/branch/test_branch_a/release/0.0.1/?foo=bar
--- response_body_json_eval
{
	"error" => "get argument foo=bar not recognised"
}
--- error_code: 400
--- no_error_log
[error]
