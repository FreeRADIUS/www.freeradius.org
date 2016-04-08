local cjson     = require "cjson"
local ngx       = require "ngx"
local common    = require "lib.common"

local uri       = ngx.var.uri
local component = uri:match(common.base_url .. "/component/([^/]+)/")
local json      = common.get_json_file(common.srv_path .. "/" .. "component" .. "/" .. component .. ".json")

if not json then
   ngx.exit(ngx.HTTP_NOT_FOUND)
end

local get_args  = ngx.req.get_uri_args()
local max_nest  = 0

-- Check it's a number...
if get_args.expansion_depth then
   max_nest = tonumber(get_args.expansion_depth)
   if not max_nest then
      ngx.exit(ngx.HTTP_BAD_REQUEST)
   end
end

-- Server side expansion of URL fields using subrequests
if max_nest > 0 then
   local res = common.resolve_urls(json, max_nest)
   if res == ngx.HTTP_NOT_FOUND then
      ngx.say("{ \"error\": \"Couldn't find resource referenced by expansion URL\" }")
      ngx.exit(res)
   end
   if res ~= ngx.OK then
      ngx.exit(res)
   end
end

ngx.say(cjson.encode(json));
ngx.exit(ngx.OK)
