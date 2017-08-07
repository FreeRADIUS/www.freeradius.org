use FindBin qw/$Bin/;
use lib "$Bin/lib";
use FreeRADIUS::Test::helper;

run_tests();

__DATA__

=== TEST 1: Component index pagination
Verify we only see entry 1

--- main_config
env TEST_DATA;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/component/$  {
	content_by_lua_file $document_root/api/info/bin/component_index.lua;
}
--- request
GET /api/info/component/?paginate_start=0&paginate_end=0
--- response_body_json_eval
[
	{
		'name'	=> 'rlm_test_a',
		'url'	=> '/api/info/component/rlm_test_a/'
	}
];
--- error_code: 200
--- no_error_log
[error]

=== TEST 2: Component index pagination
Verify we only see entries 1-2

--- main_config
env TEST_DATA;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/component/$  {
	content_by_lua_file $document_root/api/info/bin/component_index.lua;
}
--- request
GET /api/info/component/?paginate_start=1&paginate_end=2
--- response_body_json_eval
[
	{
		'name'	=> 'rlm_test_a_sub_a',
		'url'	=> '/api/info/component/rlm_test_a_sub_a/'
	},
	{
		'name'	=> 'rlm_test_a_sub_b',
		'url'	=> '/api/info/component/rlm_test_a_sub_b/'
	}
];
--- error_code: 200
--- no_error_log
[error]

=== TEST 3: Component index pagination
Verify we only see entry 3

--- main_config
env TEST_DATA;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/component/$  {
	content_by_lua_file $document_root/api/info/bin/component_index.lua;
}
--- request
GET /api/info/component/?paginate_start=3
--- response_body_json_eval
[
	{
		'name'	=> 'rlm_test_b',
		'url'	=> '/api/info/component/rlm_test_b/'
	}
];
--- error_code: 200
--- no_error_log
[error]

=== TEST 4: Component index pagination
Verify we see everything up to component 3

--- main_config
env TEST_DATA;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/component/$  {
	content_by_lua_file $document_root/api/info/bin/component_index.lua;
}
--- request
GET /api/info/component/?paginate_end=2
--- response_body_json_eval
[
	{
		'name'	=> 'rlm_test_a',
		'url'	=> '/api/info/component/rlm_test_a/'
	},
	{
		'name'	=> 'rlm_test_a_sub_a',
		'url'	=> '/api/info/component/rlm_test_a_sub_a/'
	},
	{
		'name'	=> 'rlm_test_a_sub_b',
		'url'	=> '/api/info/component/rlm_test_a_sub_b/'
	}
];
--- error_code: 200
--- no_error_log
[error]

=== TEST 5: Component index pagination - paginate_start invalid arg
Should get 400 error on invalid paginate_start

--- main_config
env TEST_DATA;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/component/$  {
	content_by_lua_file $document_root/api/info/bin/component_index.lua;
}
--- request
GET /api/info/component/?paginate_start=-1
--- response_body_json_eval
{
	'error' => 'paginate_start must be a positive integer'
};
--- error_code: 400
--- no_error_log
[error]

=== TEST 6: Component index pagination - paginate_start invalid arg
Should get 400 error on invalid paginate_start

--- main_config
env TEST_DATA;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/component/$  {
	content_by_lua_file $document_root/api/info/bin/component_index.lua;
}
--- request
GET /api/info/component/?paginate_start=bob
--- response_body_json_eval
{
	'error' => 'paginate_start must be a positive integer'
};
--- error_code: 400
--- no_error_log
[error]

=== TEST 7: Component index pagination - paginate_end invalid arg
Should get 400 error on invalid paginate_end

--- main_config
env TEST_DATA;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/component/$  {
	content_by_lua_file $document_root/api/info/bin/component_index.lua;
}
--- request
GET /api/info/component/?paginate_end=-1
--- response_body_json_eval
{
	'error' => 'paginate_end must be a positive integer'
};
--- error_code: 400
--- no_error_log
[error]

=== TEST 8: Component index pagination - paginate_end invalid arg
Should get 400 error on invalid paginate_end

--- main_config
env TEST_DATA;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/component/$  {
	content_by_lua_file $document_root/api/info/bin/component_index.lua;
}
--- request
GET /api/info/component/?paginate_end=foo
--- response_body_json_eval
{
	'error' => 'paginate_end must be a positive integer'
};
--- error_code: 400
--- no_error_log
[error]

=== TEST 9: Component index pagination - out of range starting point
Should get empty result

--- main_config
env TEST_DATA;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/component/$  {
	content_by_lua_file $document_root/api/info/bin/component_index.lua;
}
--- request
GET /api/info/component/?paginate_start=200
--- response_body_json_eval
[];
--- error_code: 200
--- no_error_log
[error]

=== TEST 10: Component index pagination - out of range ending point
Should get complete result

--- main_config
env TEST_DATA;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/component/$  {
	content_by_lua_file $document_root/api/info/bin/component_index.lua;
}
--- request
GET /api/info/component/?paginate_end=200
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

