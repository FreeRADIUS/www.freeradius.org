local cjson    	= require "cjson"
local ngx      	= require "ngx"
local common   	= require "lib.common"

local uri 			= ngx.var.uri
local get_args		= ngx.req.get_uri_args()

-- Process common arguments
local ret, msg, expansion_depth = common.common_get_args(get_args)
if ret ~= ngx.OK then
   common.fatal_error(ret, msg)
end

local branch, release = uri:match("^" .. common.base_url .. "/branch/([^/]+)/release/([^/]+)/")
local ret, json  = common.get_json_file(common.srv_path .. "/branch/" .. branch.. "/release/" .. release .. ".json")
if ret ~= ngx.OK then
   common.fatal_error(ret, "Error retrieving resource")
end

-- Server side expansion of URL fields using subrequests
if expansion_depth and expansion_depth > 0 then
   local ret = common.resolve_urls(json, expansion_depth)
   if ret ~= ngx.OK then
      common.fatal_error(ret, "Error retrieving resource referenced by expansion URL")
   end
end

ngx.say(cjson.encode(json));
ngx.exit(ngx.OK)
