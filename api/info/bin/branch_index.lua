local cjson       = require "cjson"
local ngx         = require "ngx"
local common      = require "lib.common"

local index			= common.get_index(common.srv_path .. "/branch/", common.base_url .. "/branch")
local get_args    = ngx.req.get_uri_args()

-- Process common arguments
local ret, msg, expansion_depth, keyword_expansion_depth, pagenate_start, pagenate_end = common.common_get_args(get_args)
if ret ~= ngx.OK then
   common.fatal_error(ret, msg)
end

---
---   Server side expansion of URLs
---
if expansion_depth > 0 then
   local ret = common.resolve_urls(index, expansion_depth)
   if ret == ngx.HTTP_NOT_FOUND then
      common.fatal_error(ret, "Couldn't find resource referenced by expansion URL")
   elseif ret ~= ngx.OK then
      common.fatal_error(ret)
   end
end

-- Pagenate last (for stable pagenation)
if pagenate_start or pagenate_end then
   index = common.pagenate(index, pagenate_start, pagenate_end)
end

-- Lua CJSON doesn't have a way of hinting whether empty tables are arrays or hashes
ngx.say(table.getn(index) > 0 and cjson.encode(index) or "[]");
