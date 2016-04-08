local cjson     = require "cjson"
local ngx       = require "ngx"
local common    = require "lib.common"

local index     = common.get_index(common.srv_path .. "/component/", common.base_url .. "/component")

local get_args  = ngx.req.get_uri_args()

-- Process common arguments
local ret, expansion_depth, pagenate_start, pagenate_end = common.common_get_args(get_args)
if ret ~= ngx.OK then
   ngx.exit(ret)
end

-- Filter by category
if get_args.by_category then
   local i, v
   local cache = ngx.shared.info_api_component_category
   local filtered = {}

   if not cache then
      ngx.log(ngx.ERR, "Cache not declared.  Declare with 'lua_shared_dict info_api_component_category;' in http {}")
   end

   for i, v in pairs(index) do
      local category

      if cache then
         category = cache:get(v["url"])
      end

      if not category then
         local res, json = common.get_json_file(v["url"])
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

-- Filter by keyword can't cache this one easily
if get_args.by_pattern then
   local filtered = {}

   strfind(common.base_url)

   for i, v in pairs(index) do
      m, err = ngx.re.match
   end
end

-- Server side expansion of URL fields using subrequests
if expansion_depth > 0 then
   local res = common.resolve_urls(index, expansion_depth)
   if res == ngx.HTTP_NOT_FOUND then
      ngx.say("{ \"error\": \"Couldn't find resource referenced by expansion URL\" }")
      ngx.exit(res)
   end
   if res ~= ngx.OK then
      ngx.exit(res)
   end
end

-- Pagenate last (for stable pagenation)
if pagenate_start or pagenate_end then
   index = common.pagenate(index, pagenate_start, pagenate_end)
end

ngx.say(cjson.encode(index));
