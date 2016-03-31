local cjson     = require "cjson"
local ngx       = require "ngx"
local common    = require "common"

local index     = common.get_index(common.srv_path .. "/component/", common.base_url .. "/component")

local get_args  = ngx.req.get_uri_args()
local max_nest  = 0
local pagenate_start
local pagenate_end

-- Check it's a number...
if get_args.expansion_depth then
   max_nest = tonumber(get_args.expansion_depth)
   if not max_nest then
      ngx.exit(ngx.HTTP_BAD_REQUEST)
   end
end

if get_args.pagenate_start then
   pagenate_start = tonumber(get_args.pagenate_start)
   if not pagenate_start then
      ngx.exit(ngx.HTTP_BAD_REQUEST)
   end
   pagenate_start = pagenate_start + 1
end

if get_args.pagenate_end then
   pagenate_end = tonumber(get_args.pagenate_end)
   if not pagenate_end then
      ngx.exit(ngx.HTTP_BAD_REQUEST)
   end
   pagenate_end = pagenate_end + 1
end

-- Filter by category
if get_args.by_category then
   local i, v
   local cache = ngx.shared.info_api_component_category
   local filtered = {}

   if not cache then
      ngx.log(ngx.ERR, "Cache not declared.  Declare with lua_shared_dict in http {}")
   end

   for i, v in pairs(index) do
      local category

      if cache then
         category = cache:get(v["url"])
      end

      if not category then
         local res, json = common.get_json(v["url"])
         if res ~= ngx.OK then
            return res
         end

         -- Get the category key
         if not json["category"] then
            ngx.log(ngx.ERR, "Component " .. v["name"] .. " missing category key")
            return ngx.ERROR
         end

         -- Cache the category (as that was all pretty expensive)
         if cache then
            cache:set(v["url"], json["category"])
         end
         category = json["category"]
      end

      -- Only add matching to the filtered result set
      if category == get_args.by_category then
          table.insert(filtered, v)
      end
   end

   index = filtered
end

-- Server side expansion of URL fields using subrequests
if max_nest > 0 then
   local res = common.resolve_urls(index, max_nest)
   if res == ngx.HTTP_NOT_FOUND then
      ngx.say("{ \"error\": \"Couldn't find resource referenced by expansion URL\" }")
      ngx.exit(res)
   end
   if res ~= ngx.OK then
      ngx.exit(res)
   end
end

if pagenate_start or pagenate_end then
   index = common.pagenate(index, pagenate_start, pagenate_end)
end

ngx.say(cjson.encode(index));
