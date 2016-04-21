use FindBin qw/$Bin/;
use lib "$Bin/lib";
use FreeRADIUS::Test::Common;

run_tests();

__DATA__

=== TEST 1: First level of expansions
Verify that the sane_args.expansion_depth argument is respected, and the first level of expansions is performed correctly

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
GET /api/info/component/?expansion_depth=1&order_by=name
--- response_body_json_eval
[
	{
		'name'		=> 'rlm_test_a',
		'description'	=> 'rlm_test_a description',
		'documentation_link'   => 'http://networkradius.com/doc/current/raddb/mods-available/rlm_test_a',
		'category'	=> 'authentication',
		'available'	=>
				[
					{
						"branch" => {
							"name" => "test_branch_a",
							"url" => "/api/info/branch/test_branch_a/"
						},
						"start" => {
							"name" => "0.0.1",
							"url" => "/api/info/branch/test_branch_a/release/0.0.1/"
						},
						"end" => {
							"name" => "0.0.2",
							"url" => "/api/info/branch/test_branch_a/release/0.0.2/"
						}
					},
					{
						"branch" => {
							"name" => "test_branch_b",
							"url" => "/api/info/branch/test_branch_b/"
						},
						"start" => {
							"name" => "0.0.0",
							"url" => "/api/info/branch/test_branch_b/release/0.0.0/"
						},
						"end" => {
							"name" => "0.0.0",
							"url" => "/api/info/branch/test_branch_b/release/0.0.0/"
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
					"branch" => {
						"name" => "test_branch_a",
						"url" => "/api/info/branch/test_branch_a/"
					},
					"start" => {
						"name" => "0.0.1",
						"url" => "/api/info/branch/test_branch_a/release/0.0.1/"
					},
					"end" => {
						"name" => "0.0.2",
						"url" => "/api/info/branch/test_branch_a/release/0.0.2/"
					}
				}
			]
   },
   {
      'name'		=> 'rlm_test_a_sub_b',
      'description'	=> 'rlm_test_a_sub_b description',
      'documentation_link'   => 'http://networkradius.com/doc/current/raddb/mods-available/rlm_test_a_sub_b',
      'category'	=> 'authentication',
      'available'	=>
			[
				{
					"branch" => {
						"name" => "test_branch_a",
						"url" => "/api/info/branch/test_branch_a/"
					},
					"start" => {
						"name" => "0.0.1",
						"url" => "/api/info/branch/test_branch_a/release/0.0.1/"
					},
					"end" => {
						"name" => "0.0.2",
						"url" => "/api/info/branch/test_branch_a/release/0.0.2/"
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
			"branch" => {
				"name" => "test_branch_a",
				"url" => "/api/info/branch/test_branch_a/"
			},
			"start" => {
				"name" => "1.0.0-beta1",
				"url" => "/api/info/branch/test_branch_a/release/1.0.0-beta1/"
			},
			"end" => {
				"name" => "1.0.0-pre0",
				"url" => "/api/info/branch/test_branch_a/release/1.0.0-pre0/"
			}
		}
	]
   }
];
--- error_code: 200
--- no_error_log
[error]

=== TEST 2: Multiple levels of expansions
Verify that the sane_args.expansion_depth argument is respected, and multiple levels of expansions are performed correctly

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
GET /api/info/component/?expansion_depth=2
--- response_body_json_eval

my $test_branch_a = {
	"name" => "test_branch_a",
	"description" => "test_branch_a description",
	"status" => "end of life",
	"last_release" => {
		"name" => "1.0.0-pre0",
		"url" => "/api/info/branch/test_branch_a/release/1.0.0-pre0/"
	},
	"release" => {
		"url" => "/api/info/branch/test_branch_a/release/"
	}
};

my $test_branch_b = {
	"name" => "test_branch_b",
	"description" => "test_branch_b description",
	"status" => "stable",
	"last_release" => {
		"name" => "0.0.0",
		"url" => "/api/info/branch/test_branch_b/release/0.0.0/"
	},
	"release" => {
		"url" => "/api/info/branch/test_branch_b/release/"
	}
};


my $release_0_0_1 = {
	"name" => "0.0.1",
	"summary" => "The focus of this release is testing",
	"features" => [
		{
			"description" => "Test feature",
			"component" => [
				{
					"name" => "rlm_test_a",
					"url" => "/api/info/component/rlm_test_a/"
				},
				{
					"name" => "rlm_test_b",
					"url" => "/api/info/component/rlm_test_b/"
				}
			]
		}
	],
	"defects" => [
		{
			"description" => "Test issue",
			"exploit" => JSON::true,
			"component" => [
				{
					"name" => "rlm_test_a",
					"url" => "/api/info/component/rlm_test_a/"
				},
				{
					"name" => "rlm_test_b",
					"url" => "/api/info/component/rlm_test_b/"
				}
			]
		}
	]
};

my $release_0_0_2 = {
	"name" => "0.0.2",
	"summary" => "The focus of this release is testing",
	"features" => [
		{
			"description" => "Test feature",
			"component" => [
				{
					"name" => "rlm_test_a",
					"url" => "/api/info/component/rlm_test_a/"
				},
				{
					"name" => "rlm_test_b",
					"url" => "/api/info/component/rlm_test_b/"
				}
			]
		}
	],
	"defects" => [
		{
			"description" => "Test issue",
			"exploit" => JSON::true,
			"component" => [
				{
					"name" => "rlm_test_a",
					"url" => "/api/info/component/rlm_test_a/"
				},
				{
					"name" => "rlm_test_b",
					"url" => "/api/info/component/rlm_test_b/"
				}
			]
		}
	]
};

my $release_0_0_0 = {
	"name" => "0.0.0",
	"summary" => "The focus of this release is testing",
	"features" => [
		{
			"description" => "Test feature",
			"component" => [
				{
					"name" => "rlm_test_a",
					"url" => "/api/info/component/rlm_test_a/"
				},
				{
					"name" => "rlm_test_b",
					"url" => "/api/info/component/rlm_test_b/"
				}
			]
		}
	],
	"defects" => [
		{
			"description" => "Test issue",
			"exploit" => JSON::true,
			"component" => [
				{
					"name" => "rlm_test_a",
					"url" => "/api/info/component/rlm_test_a/"
				},
				{
					"name" => "rlm_test_b",
					"url" => "/api/info/component/rlm_test_b/"
				}
			]
		}
	]
};

my $release_1_0_0_beta1 = {
	"name" => "1.0.0-beta1",
	"summary" => "The focus of this release is testing",
	"date" => "2016-04-20T05:23:30Z",
	"features" => [
		{
			"description" => "Test feature",
			"component" => [
				{
					"name" => "rlm_test_a",
					"url" => "/api/info/component/rlm_test_a/"
				},
				{
					"name" => "rlm_test_b",
					"url" => "/api/info/component/rlm_test_b/"
				}
			]
		}
	],
	"defects" => [
		{
			"description" => "Test issue",
			"exploit" => JSON::true,
			"component" => [
				{
					"name" => "rlm_test_a",
					"url" => "/api/info/component/rlm_test_a/"
				},
				{
					"name" => "rlm_test_b",
					"url" => "/api/info/component/rlm_test_b/"
				}
			]
		}
	]
};

my $release_1_0_0_pre0 = {
	"name" => "1.0.0-pre0",
	"summary" => "The focus of this release is testing",
	"date" => "2016-04-20T06:23:30Z",
	"features" => [
		{
			"description" => "Test feature 0",
			"component" => [
				{
					"name" => "rlm_test_a",
					"url" => "/api/info/component/rlm_test_a/"
				},
				{
					"name" => "rlm_test_b",
					"url" => "/api/info/component/rlm_test_b/"
				}
			]
		},
		{
			"description" => "Test feature 1",
			"component" => [
				{
					"name" => "rlm_test_a",
					"url" => "/api/info/component/rlm_test_a/"
				},
				{
					"name" => "rlm_test_b",
					"url" => "/api/info/component/rlm_test_b/"
				}
			]
		}
	],
	"defects" => [
		{
			"description" => "Test issue 0",
			"exploit" => JSON::true,
			"component" => [
				{
					"name" => "rlm_test_a",
					"url" => "/api/info/component/rlm_test_a/"
				},
				{
					"name" => "rlm_test_b",
					"url" => "/api/info/component/rlm_test_b/"
				}
			]
		},
		{
			"description" => "Test issue 1",
			"exploit" => JSON::true,
			"component" => [
				{
					"name" => "rlm_test_a",
					"url" => "/api/info/component/rlm_test_a/"
				},
				{
					"name" => "rlm_test_b",
					"url" => "/api/info/component/rlm_test_b/"
				}
			]
		}
	]
};

my $sub_a = {
   'name'         => 'rlm_test_a_sub_a',
   'description'      => 'rlm_test_a_sub_a description',
   'documentation_link'   => 'http://networkradius.com/doc/current/raddb/mods-available/rlm_test_a_sub_a',
   'category'      => 'authentication',
   'available'      =>
[
		{
			"branch" => {
				"name" => "test_branch_a",
				"url" => "/api/info/branch/test_branch_a/"
			},
			"start" => {
				"name" => "0.0.1",
				"url" => "/api/info/branch/test_branch_a/release/0.0.1/"
			},
			"end" => {
				"name" => "0.0.2",
				"url" => "/api/info/branch/test_branch_a/release/0.0.2/"
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
			"branch" => {
				"name" => "test_branch_a",
				"url" => "/api/info/branch/test_branch_a/"
			},
			"start" => {
				"name" => "0.0.1",
				"url" => "/api/info/branch/test_branch_a/release/0.0.1/"
			},
			"end" => {
				"name" => "0.0.2",
				"url" => "/api/info/branch/test_branch_a/release/0.0.2/"
			}
		}
	]
};

my $sub_a_exp = {
   'name'         => 'rlm_test_a_sub_a',
   'description'      => 'rlm_test_a_sub_a description',
   'documentation_link'   => 'http://networkradius.com/doc/current/raddb/mods-available/rlm_test_a_sub_a',
   'category'      => 'authentication',
   'available'      =>
[
		{
			"branch" => $test_branch_a,
			"start" => $release_0_0_1,
			"end" => $release_0_0_2
		}
	]
};

my $sub_b_exp = {
   'name'         => 'rlm_test_a_sub_b',
   'description'      => 'rlm_test_a_sub_b description',
   'documentation_link'   => 'http://networkradius.com/doc/current/raddb/mods-available/rlm_test_a_sub_b',
   'category'      => 'authentication',
   'available'      =>
	[
		{
			"branch" => $test_branch_a,
			"start" => $release_0_0_1,
			"end" => $release_0_0_2
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
			"branch" => $test_branch_a,
			"start" => $release_0_0_1,
			"end" => $release_0_0_2
		},
		{
			"branch" => $test_branch_b,
			"start" => $release_0_0_0,
			"end" => $release_0_0_0
		}
	],
      'dependents'      =>
         [
            $sub_a,
            $sub_b
         ]
   },
   $sub_a_exp,
   $sub_b_exp,
   {
      'name'         => 'rlm_test_b',
      'description'      => 'rlm_test_b description',
      'documentation_link'   => 'http://networkradius.com/doc/current/raddb/mods-available/rlm_test_b',
      'category'      => 'datastore',
      'available'      =>
	[
		{
			"branch" => $test_branch_a,
			"start" => $release_1_0_0_beta1,
			"end" => $release_1_0_0_pre0
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
--- error_code: 200
--- no_error_log
[error]
