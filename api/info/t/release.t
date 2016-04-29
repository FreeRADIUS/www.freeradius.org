use FindBin qw/$Bin/;
use lib "$Bin/lib";
use FreeRADIUS::Test::helper;

run_tests();

__DATA__

=== TEST 1: Release
Verify we get info about a release

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
GET /api/info/branch/test_branch_a/release/0.0.1/
--- response_body_json_eval
{
	"name"		=> "0.0.1",
	"summary"	=> "The focus of this release is testing",
	"features"	=> [
		{
			"description"	=> "Test feature",
			"component"	=> [
				{
					"name"	=> "rlm_test_a",
					"url"	=> "/api/info/component/rlm_test_a/"
				},
				{
					"name"	=> "rlm_test_b",
					"url"	=> "/api/info/component/rlm_test_b/"
				}
			]
		}
	],
	"defects" => [
		{
			"description"	=> "Test issue",
			"exploit"	=> JSON::true,
			"component"	=> [
				{
					"name"	=> "rlm_test_a",
					"url"	=> "/api/info/component/rlm_test_a/"
				},
				{
					"name"	=> "rlm_test_b",
					"url"	=> "/api/info/component/rlm_test_b/"
				}
			]
		}
	]
};
--- error_code: 200
--- no_error_log
[error]

