use FindBin qw/$Bin/;
use lib "$Bin/lib";
use FreeRADIUS::Test::helper;

run_tests();

__DATA__

=== TEST 1: Component index pagenation
Verify we only see entry 1

--- main_config
env TEST_DATA;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/component/$  {
	content_by_lua_file $document_root/api/info/bin/component_index.lua;
}
--- request
GET /api/info/component/?pagenate_start=0&pagenate_end=0
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

=== TEST 2: Component index pagenation
Verify we only see entries 1-2

--- main_config
env TEST_DATA;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/component/$  {
	content_by_lua_file $document_root/api/info/bin/component_index.lua;
}
--- request
GET /api/info/component/?pagenate_start=1&pagenate_end=2
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

=== TEST 3: Component index pagenation
Verify we only see entry 3

--- main_config
env TEST_DATA;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/component/$  {
	content_by_lua_file $document_root/api/info/bin/component_index.lua;
}
--- request
GET /api/info/component/?pagenate_start=3
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

=== TEST 4: Component index pagenation
Verify we see everything up to component 3

--- main_config
env TEST_DATA;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/component/$  {
	content_by_lua_file $document_root/api/info/bin/component_index.lua;
}
--- request
GET /api/info/component/?pagenate_end=2
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

=== TEST 5: Component index pagenation - pagenate_start invalid arg
Should get 400 error on invalid pagenate_start

--- main_config
env TEST_DATA;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/component/$  {
	content_by_lua_file $document_root/api/info/bin/component_index.lua;
}
--- request
GET /api/info/component/?pagenate_start=-1
--- response_body_json_eval
{
	'error' => 'pagenate_start must be a positive integer'
};
--- error_code: 400
--- no_error_log
[error]

=== TEST 6: Component index pagenation - pagenate_start invalid arg
Should get 400 error on invalid pagenate_start

--- main_config
env TEST_DATA;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/component/$  {
	content_by_lua_file $document_root/api/info/bin/component_index.lua;
}
--- request
GET /api/info/component/?pagenate_start=bob
--- response_body_json_eval
{
	'error' => 'pagenate_start must be a positive integer'
};
--- error_code: 400
--- no_error_log
[error]

=== TEST 7: Component index pagenation - pagenate_end invalid arg
Should get 400 error on invalid pagenate_end

--- main_config
env TEST_DATA;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/component/$  {
	content_by_lua_file $document_root/api/info/bin/component_index.lua;
}
--- request
GET /api/info/component/?pagenate_end=-1
--- response_body_json_eval
{
	'error' => 'pagenate_end must be a positive integer'
};
--- error_code: 400
--- no_error_log
[error]

=== TEST 8: Component index pagenation - pagenate_end invalid arg
Should get 400 error on invalid pagenate_end

--- main_config
env TEST_DATA;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/component/$  {
	content_by_lua_file $document_root/api/info/bin/component_index.lua;
}
--- request
GET /api/info/component/?pagenate_end=foo
--- response_body_json_eval
{
	'error' => 'pagenate_end must be a positive integer'
};
--- error_code: 400
--- no_error_log
[error]

=== TEST 9: Component index pagenation - out of range starting point
Should get empty result

--- main_config
env TEST_DATA;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/component/$  {
	content_by_lua_file $document_root/api/info/bin/component_index.lua;
}
--- request
GET /api/info/component/?pagenate_start=200
--- response_body_json_eval
[];
--- error_code: 200
--- no_error_log
[error]

=== TEST 10: Component index pagenation - out of range ending point
Should get complete result

--- main_config
env TEST_DATA;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/info/component/$  {
	content_by_lua_file $document_root/api/info/bin/component_index.lua;
}
--- request
GET /api/info/component/?pagenate_end=200
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

