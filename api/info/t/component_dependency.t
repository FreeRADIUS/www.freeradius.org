use FindBin qw/$Bin/;
use lib "$Bin/lib";
use FreeRADIUS::Test::Common;

run_tests();

__DATA__

=== TEST 1: Component category
Verify we get entries representing components of specific category

--- main_config
env TEST_DATA;
--- http_config
lua_shared_dict info_api_file_cache 5m;
lua_shared_dict info_api_component_category 5m;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/component/$  {
	content_by_lua_file $document_root/api/info/bin/component_index.lua;
}
location ~ ^/api/info/component/[.0-9a-z_-]+/$ {
	content_by_lua_file $document_root/api/info/bin/component.lua;
}
--- request
GET /api/info/component/?by_dependency_on=rlm_test_a
--- response_body_json_eval
[
   {
      'name'  => 'rlm_test_a_sub_a',
      'url'   => '/api/info/component/rlm_test_a_sub_a/'
   },
   {
      'name'  => 'rlm_test_a_sub_b',
      'url'   => '/api/info/component/rlm_test_a_sub_b/'
   }
];
--- error_code: 200
--- no_error_log
[error]

=== TEST 2: Check restriction of component name chars

--- main_config
env TEST_DATA;
--- http_config
lua_shared_dict info_api_file_cache 5m;
lua_shared_dict info_api_component_category 5m;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/component/$  {
	content_by_lua_file $document_root/api/info/bin/component_index.lua;
}
location ~ ^/api/info/component/[.0-9a-z_-]+/$ {
	content_by_lua_file $document_root/api/info/bin/component.lua;
}
--- request
GET /api/info/component/?by_dependency_on=|rlm_test_a
--- response_body_json_eval
{ "error" => 'Component names are restricted to [0-9a-z_.-]' }
--- error_code: 400
--- no_error_log
[error]

=== TEST 3: Check correct response on bad component

--- main_config
env TEST_DATA;
--- http_config
lua_shared_dict info_api_file_cache 5m;
lua_shared_dict info_api_component_category 5m;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/component/$  {
	content_by_lua_file $document_root/api/info/bin/component_index.lua;
}
location ~ ^/api/info/component/[.0-9a-z_-]+/$ {
	content_by_lua_file $document_root/api/info/bin/component.lua;
}
--- request
GET /api/info/component/?by_dependency_on=rlm_test_0
--- response_body_json_eval
{ "error" => 'Subrequest for "/api/info/component/rlm_test_0/" failed with code 404' }
--- error_code: 404
--- no_error_log
[error]
