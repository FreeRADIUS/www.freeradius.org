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
lua_shared_dict social_api_stackoverflow_cache 1m;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/social/stackoverflow$ {
   resolver 8.8.8.8;
   content_by_lua_file $document_root/api/social/bin/stackoverflow.lua;
}
--- request
GET /api/social/stackoverflow?n=1
--- response_body_json_eval
[
   {
      'body' => qq(<p>i have made a web application that i need to authenticate through a radius server,i am using free-radius for Linux and dialupadmin gui and mysql at the back-end.</p>\n\n<p>my question is, how can i get authorization info from radius response.\nhow and what type of groups i can create on the radius server that must be returned in order to maintain an Access Control List on the Web Application.</p>\n\n<p>i need to understand does radius can return The Roles and Groups information to my web application and how.\nany help would be appreciated.\nThanks</p>\n),
      'creation_date' => 1461736466,
      'link' => 'http://stackoverflow.com/questions/36881362/authorization-with-radius-server',
      'owner' => {
         'display_name' => 'M Imtiaz',
         'link' => 'http://stackoverflow.com/users/2181155/m-imtiaz',
         'profile_image' => 'https://i.stack.imgur.com/iH8dk.jpg?s=128&g=1'
      },
      'title' => 'Authorization with Radius Server'
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
lua_shared_dict social_api_stackoverflow_cache 1m;
--- config
root $TEST_NGINX_REPOSITORY_ROOT;
location ~ ^/api/social/stackoverflow$ {
   resolver 8.8.8.8;
   content_by_lua_file $document_root/api/social/bin/stackoverflow.lua;
}
--- request
GET /api/social/stackoverflow
--- response_body_json_eval
[
   {
      'body' => qq(<p>i have made a web application that i need to authenticate through a radius server,i am using free-radius for Linux and dialupadmin gui and mysql at the back-end.</p>\n\n<p>my question is, how can i get authorization info from radius response.\nhow and what type of groups i can create on the radius server that must be returned in order to maintain an Access Control List on the Web Application.</p>\n\n<p>i need to understand does radius can return The Roles and Groups information to my web application and how.\nany help would be appreciated.\nThanks</p>\n),
      'creation_date' => 1461736466,
      'link' => 'http://stackoverflow.com/questions/36881362/authorization-with-radius-server',
      'owner' => {
         'display_name' => 'M Imtiaz',
         'link' => 'http://stackoverflow.com/users/2181155/m-imtiaz',
         'profile_image' => 'https://i.stack.imgur.com/iH8dk.jpg?s=128&g=1'
      },
      'title' => 'Authorization with Radius Server'
   },
   {
      'body' => qq(<p>The version of this freeradius is freeradius-server-2.2.3, I tried to configure it to get the Makefile.</p>\n\n<pre><code>./configure --host=arm-marvell-linux-gnueabi --with-openssl-includes=openssl_header_path --with-openssl-libraries=openssl_lib_path\n</code></pre>\n\n<p>It reported an error: \"cannot run test program while cross compiling\".</p>\n\n<blockquote>\n  <p>checking for OpenSSL version >= 0.9.7... yes\n  checking OpenSSL library and header version consistency... configure: error: in '/mnt/arm_keygoe_build/freeradius/freeradius-server-2.2.3':\n  configure: error: cannot run test program while cross compiling\n  See `config.log' for more details</p>\n</blockquote>\n\n<p>I got some information about this error from Google, it seems that a test program can't be ran on my system, because it's an arm program. A work-around is to specify a cache-file for the 'configure' script, and set some variables' value to \"yes\" in this file. However, I can't search a variable about this error.\n<a href=\"http://i.stack.imgur.com/I4MNe.png\" rel=\"nofollow\">the snapshot is here</a></p>\n\n<p>I can search the variables(e.g. ac_cv_have_pragma_pack_N) when I cross compile the xlslib. \n<a href=\"http://i.stack.imgur.com/mcbem.png\" rel=\"nofollow\">the snapshot is here</a></p>\n\n<p>Any help is greatly appreciated. Thanks very much in advance.</p>\n),
      'creation_date' => 1461646971,
      'link' => 'http://stackoverflow.com/questions/36855625/freeradius-cross-compiling-failure',
      'owner' => {
         'display_name' => 'Choes',
         'link' => 'http://stackoverflow.com/users/2152805/choes',
         'profile_image' => 'https://www.gravatar.com/avatar/c9ec37b47db2f7bea8600b7c120dee28?s=128&d=identicon&r=PG'
      },
      'title' => 'freeradius cross-compiling failure'
   },
   {
      'body' => qq(<p>I have a freeradius-mysql query to select data where <strong>acctstarttime is MORE THAN 30 days</strong>:</p>\n\n<p>below is the query:</p>\n\n<pre><code>SELECT SUM(acctinputoctets -\n           GREATEST((30 - UNIX_TIMESTAMP(acctstarttime)), 0)) +\n       SUM(acctoutputoctets -\n           GREATEST((30 - UNIX_TIMESTAMP(acctstarttime)), 0))\n  FROM radacct\n WHERE username = 'user2'\n   AND UNIX_TIMESTAMP(acctstarttime) + acctsessiontime &gt; 30\n</code></pre>\n\n<p>I would like to have a query of the same nature that selects data where <strong>acctstarttime is LESS THAN 30 days</strong> and im having a hard time. </p>\n\n<p>Can anyone help?</p>\n),
      'creation_date' => 1461565750,
      'link' => 'http://stackoverflow.com/questions/36833427/select-data-where-datetime-is-less-than-30-days',
      'owner' => {
         'display_name' => 'MarkCo_Polo',
         'link' => 'http://stackoverflow.com/users/6249875/markco-polo',
         'profile_image' => 'https://www.gravatar.com/avatar/73babcdac3db65f0b2c39985c0ac35ef?s=128&d=identicon&r=PG&f=1'
      },
      'title' => 'Select data where datetime is less than 30 days'
   }
]
--- error_code: 200
--- no_error_log
[error]
