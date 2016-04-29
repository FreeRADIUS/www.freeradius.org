use FindBin qw/$Bin/;
use lib "$Bin/lib";
use FreeRADIUS::Test::helper;

run_tests();

__DATA__

=== TEST 1: Component index
Verify we get entries representing all the components in the component directory

--- main_config
env TEST_DATA;
--- http_config
lua_shared_dict info_api_file_cache 5m;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/component/$  {
	content_by_lua_file $document_root/api/info/bin/component_index.lua;
}
--- request
GET /api/info/component/?order_by=name
--- response_body_json_eval
[
   {
      'name'  => 'rlm_test_a',
      'url'   => '/api/info/component/rlm_test_a/'
   },
   {
      'name'  => 'rlm_test_a_sub_a',
      'url'   => '/api/info/component/rlm_test_a_sub_a/'
   },
   {
      'name'  => 'rlm_test_a_sub_b',
      'url'   => '/api/info/component/rlm_test_a_sub_b/'
   },
   {
      'name'  => 'rlm_test_b',
      'url'   => '/api/info/component/rlm_test_b/'
   }
];
--- error_code: 200
--- no_error_log
[error]

=== TEST 2: Check using both dependency and category filters is disallowed
--- main_config
env TEST_DATA;
--- http_config
lua_shared_dict info_api_file_cache 5m;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/component/$  {
	content_by_lua_file $document_root/api/info/bin/component_index.lua;
}
--- request
GET /api/info/component/?by_category=unknown&by_dependency_on=rlm_test
--- response_body_json_eval
{ 'error' => 'by_category and by_dependency_on filters are mutually exclusive' };
--- error_code: 400
--- no_error_log
[error]
