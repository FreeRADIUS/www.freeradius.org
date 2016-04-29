use FindBin qw/$Bin/;
use lib "$Bin/lib";
use FreeRADIUS::Test::Common;

run_tests();

__DATA__

=== TEST 1: Component keyword search regex
Return entries with fields matching the specified pattern

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
GET /api/info/component/?by_keyword=regex:_su[b]_
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

=== TEST 2: Component keyword search regex
Return entries with fields matching the specified pattern

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
GET /api/info/component/?by_keyword=regex:_[s]ub_
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

=== TEST 3: Component keyword search lua find
Return entries with fields matching the specified pattern

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
GET /api/info/component/?by_keyword=lua:_su%a_
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

=== TEST 4: Component keyword search bad regex
Verify useful message is displayed on bad pattern

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
GET /api/info/component/?by_keyword=regex:_[sub_
--- response_body_json_eval
{ 'error' => 'Missing terminating ] for character class in "_[sub_"' };
--- error_code: 400
--- no_error_log
[error]

=== TEST 5: Component keyword search bad lua find pattern
Verify useful message is displayed on bad pattern

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
GET /api/info/component/?by_keyword=lua:_su[_
--- response_body_json_eval
{ 'error' => "Malformed pattern (missing ']')" }
--- error_code: 400
--- no_error_log
[error]

=== TEST 6: Component keyword search with expansion depth
Return entries with fields matching the specified pattern

--- main_config
env TEST_DATA;
--- http_config
lua_shared_dict info_api_file_cache 5m;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/component/$  {
   content_by_lua_file $document_root/api/info/bin/component_index.lua;
}
location ~ ^/api/info/component/[.0-9a-z_-]+/$ {
   content_by_lua_file $document_root/api/info/bin/component.lua;
}
--- request
GET /api/info/component/?keyword_expansion_depth=1&expansion_depth=1&by_keyword=regex:data
--- response_body_json_eval
[
   {
      'name'         => 'rlm_test_b',
      'description'      => 'rlm_test_b description',
      'documentation_link'   => 'http://networkradius.com/doc/current/raddb/mods-available/rlm_test_b',
      'category'      => 'datastore',
      'available'      =>
         [
         	{
			"branch" => {
				"name" => "test_branch_a",
				"url" => "\/api\/info\/branch\/test_branch_a\/"
			},
			"end" => {
				"name" => "1.0.0-pre0",
				"url" => "\/api\/info\/branch\/test_branch_a\/release\/1.0.0-pre0\/"
			},
			"start" => {
				"name" => "1.0.0-beta1",
				"url" => "\/api\/info\/branch\/test_branch_a\/release\/1.0.0-beta1\/"
			}
		}
         ]
   }
];
--- error_code: 200
--- no_error_log
[error]

=== TEST 7: Component keyword search with expansion depth and greater keyword_expansion_depth
Return entries with fields matching the specified pattern

--- main_config
env TEST_DATA;
--- http_config
lua_shared_dict info_api_file_cache 5m;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/component/$  {
   content_by_lua_file $document_root/api/info/bin/component_index.lua;
}
location ~ ^/api/info/component/[.0-9a-z_-]+/$ {
   content_by_lua_file $document_root/api/info/bin/component.lua;
}
location ~ ^/api/info/branch/$ {
   content_by_lua_file $document_root/api/info/bin/branch_index.lua;
}
location ~ ^/api/info/branch/[.0-9a-z_-]+/$ {
   content_by_lua_file $document_root/api/info/bin/branch.lua;
}
location ~ ^/api/info/branch/[.0-9a-z_-]+/release/$ {
   content_by_lua_file $document_root/api/info/bin/release_index.lua;
}
location ~ ^/api/info/branch/[.0-9a-z_-]+/release/[.0-9a-z_-]+/$ {
   content_by_lua_file $document_root/api/info/bin/release.lua;
}
--- request
GET /api/info/component/?keyword_expansion_depth=2&expansion_depth=1&by_keyword=regex:data
--- response_body_json_eval
[
   {
      'name'         => 'rlm_test_b',
      'description'      => 'rlm_test_b description',
      'documentation_link'   => 'http://networkradius.com/doc/current/raddb/mods-available/rlm_test_b',
      'category'      => 'datastore',
      'available'      =>
         [
         	{
			"branch" => {
				"name" => "test_branch_a",
				"url" => "\/api\/info\/branch\/test_branch_a\/"
			},
			"end" => {
				"name" => "1.0.0-pre0",
				"url" => "\/api\/info\/branch\/test_branch_a\/release\/1.0.0-pre0\/"
			},
			"start" => {
				"name" => "1.0.0-beta1",
				"url" => "\/api\/info\/branch\/test_branch_a\/release\/1.0.0-beta1\/"
			}
		}
         ]
   }
];
--- error_code: 200
--- no_error_log
[error]

=== TEST 8: Component keyword search without expansion depth
Return entries with fields matching the specified pattern

--- main_config
env TEST_DATA;
--- http_config
lua_shared_dict info_api_file_cache 5m;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/component/$  {
   content_by_lua_file $document_root/api/info/bin/component_index.lua;
}
location ~ ^/api/info/component/[.0-9a-z_-]+/$ {
   content_by_lua_file $document_root/api/info/bin/component.lua;
}
--- request
GET /api/info/component/?keyword_expansion_depth=1&by_keyword=regex:data
--- response_body_json_eval
[
   {
      'name'  => 'rlm_test_b',
      'url'   => '/api/info/component/rlm_test_b/'
   }
];
--- error_code: 200
--- no_error_log
[error]

=== TEST 9: Component keyword search with string comparison
Return entries with fields matching the specified pattern

--- main_config
env TEST_DATA;
--- http_config
lua_shared_dict info_api_file_cache 5m;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/component/$  {
   content_by_lua_file $document_root/api/info/bin/component_index.lua;
}
location ~ ^/api/info/component/[.0-9a-z_-]+/$ {
   content_by_lua_file $document_root/api/info/bin/component.lua;
}
--- request
GET /api/info/component/?keyword_expansion_depth=1&by_keyword=datastore
--- response_body_json_eval
[
   {
      'name'  => 'rlm_test_b',
      'url'   => '/api/info/component/rlm_test_b/'
   }
];
--- error_code: 200
--- no_error_log
[error]

=== TEST 10: Component keyword search with string comparison
Return entries with fields matching the specified pattern

--- main_config
env TEST_DATA;
--- http_config
lua_shared_dict info_api_file_cache 5m;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/component/$  {
   content_by_lua_file $document_root/api/info/bin/component_index.lua;
}
location ~ ^/api/info/component/[.0-9a-z_-]+/$ {
   content_by_lua_file $document_root/api/info/bin/component.lua;
}
--- request
GET /api/info/component/?keyword_expansion_depth=1&by_keyword=literal:datastore
--- response_body_json_eval
[
   {
      'name'  => 'rlm_test_b',
      'url'   => '/api/info/component/rlm_test_b/'
   }
];
--- error_code: 200
--- no_error_log
[error]
