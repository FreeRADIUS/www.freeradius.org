local cjson    	      = require "cjson"
local ngx            	= require "ngx"

local helper         	= require "lib.helper"
local validate          = require "lib.validate"

local uri 			      = ngx.var.uri

local get_args          = ngx.req.get_uri_args()
local sane_args
local ret, err

-- Process helper arguments
sane_args, err = validate.get_args(get_args)
if not sane_args then
   helper.fatal_error(ngx.HTTP_BAD_REQUEST, err)
end

ret, err = validate.get_args_unknown(get_args)
if not ret then
   helper.fatal_error(ngx.HTTP_BAD_REQUEST, err)
end

local match = ngx.re.match(uri, "^" .. helper.config.base_url .. "/branch/([^/]+)/release/([^/]+)/", "jo")
local branch = match[1]
local release = match[2]

local ret, json  = helper.get_json_file(helper.config.srv_path .. "/branch/" .. branch.. "/release/" .. release .. ".json")
if ret == ngx.HTTP_NOT_FOUND then
   helper.fatal_error(ret, "Release \"" .. rlease .. "\" not found")
elseif ret ~= ngx.OK then
   helper.fatal_error(ret)
end

-- Server side expansion of URL fields using subrequests
if sane_args.expansion_depth and sane_args.expansion_depth > 0 then
   local ret = helper.resolve_urls(json, sane_args.expansion_depth)
   if ret ~= ngx.OK then
      helper.fatal_error(ret, "Error retrieving nested object (" .. tostring(ret) .. ")")
   end
end

ngx.say(cjson.encode(json));
ngx.exit(ngx.OK)
