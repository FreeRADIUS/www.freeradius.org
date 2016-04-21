local cjson    	      = require "cjson"
local ngx      	      = require "ngx"

local common   	      = require "lib.common"
local uri 			      = ngx.var.uri

local get_args          = ngx.req.get_uri_args()
local sane_args
local ret, err

-- Process common arguments
sane_args, err = common.common_get_args(get_args)
if not sane_args then
   common.fatal_error(ngx.HTTP_BAD_REQUEST, err)
end

local component = uri:match("^" .. common.base_url .. "/component/([^/]+)/")
local ret, json  = common.get_json_file(common.srv_path .. "/" .. "component" .. "/" .. component .. ".json")
if ret == ngx.HTTP_NOT_FOUND then
   common.fatal_error(ret, "Component \"" .. component .. "\" not found")
elseif ret ~= ngx.OK then
   common.fatal_error(ret)
end

-- Server side expansion of URL fields using subrequests
if sane_args.expansion_depth and sane_args.expansion_depth > 0 then
   local ret = common.resolve_urls(json, sane_args.expansion_depth)
   if ret ~= ngx.OK then
      common.fatal_error(ret, "Error retrieving nested object (" .. tostring(ret) .. ")")
   end
end

ngx.say(cjson.encode(json));
ngx.exit(ngx.OK)
