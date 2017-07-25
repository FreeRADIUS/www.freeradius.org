use FindBin qw/$Bin/;
use lib "$Bin/lib";
use FreeRADIUS::Test::helper;

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
GET /api/info/component/?by_category=authentication&order_by=name
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
        }
];
--- error_code: 200
--- no_error_log
[error]

=== TEST 2: Component category (unknown)
Verify we get an empty 200 response if the category is unknown

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
GET /api/info/component/?by_category=unknown
--- response_body_json_eval
[];
--- error_code: 200
--- no_error_log
[error]

=== TEST 3: Component category and pagenate
Only pull back the first result for a category

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
GET /api/info/component/?by_category=authentication&pagenate_start=0&pagenate_end=0
--- response_body_json_eval
[
   {
      'name'  => 'rlm_test_a',
      'url'   => '/api/info/component/rlm_test_a/'
   }
];
--- error_code: 200
--- no_error_log
[error]

=== TEST 4: Check restriction on category name chars

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
GET /api/info/component/?by_category=|authenticate
--- response_body_json_eval
{ "error" => 'category names are restricted to [a-z-]' }
--- error_code: 400
--- no_error_log
[error]
