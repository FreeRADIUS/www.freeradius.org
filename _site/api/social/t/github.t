use FindBin qw/$Bin/;
use lib "$Bin/lib";
use FreeRADIUS::Test::helper;

run_tests();

__DATA__

=== TEST 1: Get an entry from GitHub
Get a single entry from GitHub

--- main_config
env TEST_DATA;
--- http_config
lua_shared_dict social_api_github_cache 1m;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/social/github$ {
   resolver 8.8.8.8;
   content_by_lua_file $document_root/api/social/bin/github.lua;
}
--- request
GET /api/social/github?n=1
--- response_body_json_eval
[
   {
      'author' => {
         'avatar_url' => 'https://avatars.githubusercontent.com/u/791758?v=3',
         'html_url' => 'https://github.com/arr2036'
      },
      'commit' => {
         'author' => {
            'date' => '2016-04-30T22:31:28Z',
            'name' => 'Arran Cudbard-Bell'
         },
         'committer' => {
            'date' => '2016-04-30T22:31:28Z',
            'name' => 'Arran Cudbard-Bell'
         },
         'verification' => {
            'reason' => 'Information not provided by GitHub',
            'verified' => JSON::false
         }
      },
      'committer' => {
         'avatar_url' => 'https://avatars.githubusercontent.com/u/791758?v=3',
         'html_url' => 'https://github.com/arr2036'
      },
      'html_url' => 'https://github.com/FreeRADIUS/freeradius-server/commit/f07dba0e79460ff97e293fee3a2c104d2e8d3df5',
      'sha' => 'f07dba0e79460ff97e293fee3a2c104d2e8d3df5'
   }
]
--- error_code: 200
--- no_error_log
[error]

=== TEST 2: Get an entry from GitHub
Get a single entry from GitHub

--- main_config
env TEST_DATA;
--- http_config
lua_shared_dict social_api_github_cache 1m;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/social/github$ {
   resolver 8.8.8.8;
   content_by_lua_file $document_root/api/social/bin/github.lua;
}
--- request
GET /api/social/github
--- response_body_json_eval
[
   {
      'author' => {
         'avatar_url' => 'https://avatars.githubusercontent.com/u/791758?v=3',
         'html_url' => 'https://github.com/arr2036'
      },
      'commit' => {
         'author' => {
            'date' => '2016-04-30T22:31:28Z',
            'name' => 'Arran Cudbard-Bell'
         },
         'committer' => {
            'date' => '2016-04-30T22:31:28Z',
            'name' => 'Arran Cudbard-Bell'
         },
         'verification' => {
            'reason' => 'Information not provided by GitHub',
            'verified' => JSON::false
         }
      },
      'committer' => {
         'avatar_url' => 'https://avatars.githubusercontent.com/u/791758?v=3',
         'html_url' => 'https://github.com/arr2036'
      },
      'html_url' => 'https://github.com/FreeRADIUS/freeradius-server/commit/f07dba0e79460ff97e293fee3a2c104d2e8d3df5',
      'sha' => 'f07dba0e79460ff97e293fee3a2c104d2e8d3df5'
   },
   {
      'author' => {
         'avatar_url' => 'https://avatars.githubusercontent.com/u/791758?v=3',
         'html_url' => 'https://github.com/arr2036'
      },
      'commit' => {
         'author' => {
            'date' => '2016-04-30T05:07:08Z',
            'name' => 'Arran Cudbard-Bell'
         },
         'committer' => {
            'date' => '2016-04-30T05:07:08Z',
            'name' => 'Arran Cudbard-Bell'
         },
         'verification' => {
            'reason' => 'Information not provided by GitHub',
            'verified' => JSON::false
         }
      },
      'committer' => {
         'avatar_url' => 'https://avatars.githubusercontent.com/u/791758?v=3',
         'html_url' => 'https://github.com/arr2036'
      },
      'html_url' => 'https://github.com/FreeRADIUS/freeradius-server/commit/943888b4a8413d7f65214fbd6506ba3487158d07',
      'sha' => '943888b4a8413d7f65214fbd6506ba3487158d07'
   },
   {
      'author' => {
         'avatar_url' => 'https://avatars.githubusercontent.com/u/791758?v=3',
         'html_url' => 'https://github.com/arr2036'
      },
      'commit' => {
         'author' => {
            'date' => '2016-04-30T05:03:54Z',
            'name' => 'Arran Cudbard-Bell'
         },
         'committer' => {
            'date' => '2016-04-30T05:03:54Z',
            'name' => 'Arran Cudbard-Bell'
         },
         'verification' => {
            'reason' => 'Information not provided by GitHub',
            'verified' => JSON::false
         }
      },
      'committer' => {
         'avatar_url' => 'https://avatars.githubusercontent.com/u/791758?v=3',
         'html_url' => 'https://github.com/arr2036'
      },
      'html_url' => 'https://github.com/FreeRADIUS/freeradius-server/commit/26bf7ca08bbff5316649f3b67cc63f612d8500f2',
      'sha' => '26bf7ca08bbff5316649f3b67cc63f612d8500f2'
   }
]
--- error_code: 200
--- no_error_log
[error]
