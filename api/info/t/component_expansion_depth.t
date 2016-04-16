use FindBin qw/$Bin/;
use lib "$Bin/lib";
use FreeRADIUS::Test::Common;

run_tests();

__DATA__

=== TEST 1: First level of expansions
Verify that the expansion_depth argument is respected, and the first level of expansions is performed correctly

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
GET /api/info/component/?expansion_depth=1
--- response_body_json_eval
[
   {
      'name'         => 'rlm_test_a',
      'description'      => 'rlm_test_a description',
      'documentation_link'   => 'http://networkradius.com/doc/current/raddb/mods-available/rlm_test_a',
      'category'      => 'authentication',
      'available'      =>
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
      'dependents'      =>
         [
            {
               'name'    => 'rlm_test_a_sub_a',
               'url'   => '/api/info/component/rlm_test_a_sub_a/'
            },
            {
               'name'    => 'rlm_test_a_sub_b',
               'url'   => '/api/info/component/rlm_test_a_sub_b/'
            }
         ]
   },
   {
      'name'         => 'rlm_test_a_sub_a',
      'description'      => 'rlm_test_a_sub_a description',
      'documentation_link'   => 'http://networkradius.com/doc/current/raddb/mods-available/rlm_test_a_sub_a',
      'category'      => 'authentication',
      'available'      =>
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
         ]
   },
   {
      'name'         => 'rlm_test_a_sub_b',
      'description'      => 'rlm_test_a_sub_b description',
      'documentation_link'   => 'http://networkradius.com/doc/current/raddb/mods-available/rlm_test_a_sub_b',
      'category'      => 'authentication',
      'available'      =>
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
         ]
   },
   {
      'name'         => 'rlm_test_b',
      'description'      => 'rlm_test_b description',
      'documentation_link'   => 'http://networkradius.com/doc/current/raddb/mods-available/rlm_test_b',
      'category'      => 'datastore',
      'available'      =>
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
            },
            {
               'branch' => 'v3.0.x',
               'start' => {
                  'major' => 3,
                  'minor' => 0,
                  'release' => 0
               },

               'end' => {
                  'major' => 3,
                  'minor' => 0,
                  'release' => 12
               }
            }
         ]
   }
];
--- error_code: 200
--- no_error_log
[error]

=== TEST 2: Multiple levels of expansions
Verify that the expansion_depth argument is respected, and multiple levels of expansions are performed correctly

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
GET /api/info/component/?expansion_depth=2
--- response_body_json_eval
my $sub_a = {
   'name'         => 'rlm_test_a_sub_a',
   'description'      => 'rlm_test_a_sub_a description',
   'documentation_link'   => 'http://networkradius.com/doc/current/raddb/mods-available/rlm_test_a_sub_a',
   'category'      => 'authentication',
   'available'      =>
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
      ]
};

my $sub_b = {
   'name'         => 'rlm_test_a_sub_b',
   'description'      => 'rlm_test_a_sub_b description',
   'documentation_link'   => 'http://networkradius.com/doc/current/raddb/mods-available/rlm_test_a_sub_b',
   'category'      => 'authentication',
   'available'      =>
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
      ]
};

[
   {
      'name'         => 'rlm_test_a',
      'description'      => 'rlm_test_a description',
      'documentation_link'   => 'http://networkradius.com/doc/current/raddb/mods-available/rlm_test_a',
      'category'      => 'authentication',
      'available'      =>
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
      'dependents'      =>
         [
            $sub_a,
            $sub_b
         ]
   },
   $sub_a,
   $sub_b,
   {
      'name'         => 'rlm_test_b',
      'description'      => 'rlm_test_b description',
      'documentation_link'   => 'http://networkradius.com/doc/current/raddb/mods-available/rlm_test_b',
      'category'      => 'datastore',
      'available'      =>
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
            },
            {
               'branch' => 'v3.0.x',
               'start' => {
                  'major' => 3,
                  'minor' => 0,
                  'release' => 0
               },

               'end' => {
                  'major' => 3,
                  'minor' => 0,
                  'release' => 12
               }
            }
         ]
   }
];
--- error_code: 200
--- no_error_log
[error]

=== TEST 3: Bad expansion depth value
Should get error

--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/component/$  {
   content_by_lua_file $document_root/api/info/bin/component_index.lua;
}
--- request
GET /api/info/component/?expansion_depth=foo
--- response_body_json_eval
{
   'error' => 'expansion_depth must be a positive integer'
};
--- error_code: 400
--- no_error_log
[error]

=== TEST 4: Bad expansion depth value
Should get error

--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/component/$  {
   content_by_lua_file $document_root/api/info/bin/component_index.lua;
}
--- request
GET /api/info/component/?expansion_depth=-1
--- response_body_json_eval
{
   'error' => 'expansion_depth must be a positive integer'
};
--- error_code: 400
--- no_error_log
[error]

=== TEST 5: Expansion level 0 should perform no expansions
Should get error
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
GET /api/info/component/?expansion_depth=0
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

