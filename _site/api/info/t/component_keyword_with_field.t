use FindBin qw/$Bin/;
use lib "$Bin/lib";
use FreeRADIUS::Test::helper;

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
GET /api/info/component/?keyword_expansion_depth=2&by_keyword=2016-04-20T05:23:30Z&keyword_field=date
--- response_body_json_eval
[
   {
      "name" => "rlm_test_b",
      "url" => "\/api\/info\/component\/rlm_test_b\/"
   }
];
--- error_code: 200
--- no_error_log
[error]
