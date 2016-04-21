local cjson    	      = require "cjson"
local ngx      	      = require "ngx"

local common            = require "lib.common"

local uri		         = ngx.var.uri

local get_args          = ngx.req.get_uri_args()
local sane_args
local ret, err

-- Process common arguments
sane_args, err = common.common_get_args(get_args)
if not sane_args then
   common.fatal_error(ngx.HTTP_BAD_REQUEST, err)
end

local branch = uri:match("^" .. common.base_url .. "/branch/([^/]+)/")
local ret, json = common.get_json_file(common.srv_path .. "/branch/" .. branch .. ".json")
if ret == ngx.HTTP_NOT_FOUND then
   common.fatal_error(ret, "Branch \"" .. branch .. "\" not found")
elseif ret ~= ngx.OK then
   common.fatal_error(ret)
end

-- Add link to releases to allow expansion
json.release = { url = common.base_url .. "/branch/" .. branch .. "/release/" }
ret, json.last_release = common.get_json_subrequest(json.release.url .. "?pagenate_start=0&pagenate_end=0")
if ret == ngx.HTTP_NOT_FOUND then
   json.last_release = nil
elseif ret ~= ngx.OK then
   common.fatal_error(ret, "Error retrieving release list")
else
   json.last_release = json.last_release[1]  -- Releases are ordered DESC
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
