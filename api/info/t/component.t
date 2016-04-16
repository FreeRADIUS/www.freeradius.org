use FindBin qw/$Bin/;
use lib "$Bin/lib";
use FreeRADIUS::Test::Common;

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
location ~ ^/api/info/component/[.0-9a-z_-]+/$ {
   content_by_lua_file $document_root/api/info/bin/component.lua;
}
--- request
GET /api/info/component/rlm_test_a/
--- response_body_json_eval
{
   'name'               => 'rlm_test_a',
   'description'        => 'rlm_test_a description',
   'documentation_link' => 'http://networkradius.com/doc/current/raddb/mods-available/rlm_test_a',
   'category'           => 'authentication',
   'available'          =>
      [
         {
            'branch' => 'v2.2.x',
            'start' => {
               'major' => 2,
               'minor' => 0,
               'release' => 0
            },

            'end' => {
               'major' => 2,
               'minor' => 2,
               'release' => 9
            }
         }
      ],
   'dependents'   =>
      [
         {
            'name'   => 'rlm_test_a_sub_a',
            'url'    => '/api/info/component/rlm_test_a_sub_a/'
         },
         {
            'name'   => 'rlm_test_a_sub_b',
            'url'    => '/api/info/component/rlm_test_a_sub_b/'
         }
      ]
};
--- error_code: 200
--- no_error_log
