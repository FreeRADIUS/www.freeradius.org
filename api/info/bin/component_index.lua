local cjson       = require "cjson"
local ngx         = require "ngx"
local common      = require "lib.common"

local index
local get_args    = ngx.req.get_uri_args()

local by_keyword_func, by_keyword_pattern

-- Process common arguments
local ret, msg, expansion_depth, keyword_expansion_depth, pagenate_start, pagenate_end = common.common_get_args(get_args)
if ret ~= ngx.OK then
   common.fatal_error(ret, msg)
end

-- Process by_keyword pattern (if it was provided)
if get_args.by_keyword then
   by_keyword_func, by_keyword_pattern = common.keyword_validate(get_args.by_keyword)

   -- Check the pattern's sane
   if by_keyword_func == nil then
      common.fatal_error(ngx.HTTP_BAD_REQUEST, by_keyword_pattern)
   end
end

--
--    Sanity checks
--
if get_args.by_category and get_args.by_dependency_on then
   common.fatal_error(ngx.HTTP_BAD_REQUEST, "by_category and by_dependency_on filters are mutually exclusive")
end

--
--    Filter by category
--
if get_args.by_category then
   local i, v
   local cache = ngx.shared.info_api_component_category

   if not cache then
      ngx.log(ngx.ERR, "Cache not declared.  Declare with 'lua_shared_dict info_api_component_category;' in http {}")
   end

   if not ngx.re.find(get_args.by_category, "^[a-z-]+$", "jio") then
      common.fatal_error(ngx.HTTP_BAD_REQUEST, "Category names are restricted to [a-z-]")
   end

   index = {}
   for i, v in ipairs(common.get_index(common.srv_path .. "/component/", common.base_url .. "/component")) do
      local category

      if not v["url"] then
         ngx.log(ngx.ERR, "Component " .. v["name"] .. " missing url key")
         common.fatal_error()
      end

      if cache then
         category = cache:get(v["url"])
      end

      if not category then
         local ret, json = common.get_json_subrequest(v["url"])
         if ret ~= ngx.OK then
            common.fatal_error(ngx.HTTP_INTERNAL_SERVER_ERROR,
                               "Subrequest for \"" .. v["url"] .. "\" failed with" .. tostring(ret))
         end

         -- Get the category key
         if not json["category"] then
            ngx.log(ngx.ERR, "Component " .. v["name"] .. " missing category key")
            common.fatal_error()
         end

         category = json["category"]

         -- Cache the category (as that was all pretty expensive)
         if cache then
            cache:set(v["url"], category)
         end
      end

      -- Only add matching to the filtered result set
      if category == get_args.by_category then
          table.insert(index, v)
      end
   end
--
--    Filter by dependency
--
elseif get_args.by_dependency_on then
   local url, ret, json

   if not ngx.re.find(get_args.by_dependency_on, "^[0-9a-z_.-]+$", "jio") then
      common.fatal_error(ngx.HTTP_BAD_REQUEST, "Component names are restricted to [0-9a-z_.-]")
   end

   url = common.base_url .. "/component/" .. get_args.by_dependency_on .. "/"
   ret, json = common.get_json_subrequest(url)
   if ret ~= ngx.OK then
      common.fatal_error(ret,
                         "Subrequest for \"" .. url .. "\" failed with code " .. tostring(ret))
   end

   if not json.dependents then
      common.fatal_error(ngx.HTTP_BAD_REQUEST, "Component has no dependents")
   end

   index = json.dependents
--
--    No filtering
--
else
   index = common.get_index(common.srv_path .. "/component/", common.base_url .. "/component")
end

--
--    Filter by keyword (possibly combined with previous filtering)
--
if get_args.by_keyword then
   local filtered = {}

   for i, v in ipairs(index) do
      local to_expand

      if keyword_expansion_depth > expansion_depth then
         to_expand = common.table_copy(v)
      else
         to_expand = v
      end

      if keyword_expansion_depth > 0 then
         local ret = common.resolve_urls(to_expand, keyword_expansion_depth)
         if ret == ngx.HTTP_NOT_FOUND then
            common.fatal_error(ret, "Couldn't find resource referenced by expansion URL")
         elseif ret ~= ngx.OK then
            common.fatal_error(ret)
         end
      end

      local ret, msg = common.keyword_search(to_expand, by_keyword_func,
                                             by_keyword_pattern, { 'name', 'description', 'branch', 'category' })
      if ret == nil then
         common.fatal_error(ngx.HTTP_BAD_REQUEST, msg .. "COCK")
      elseif ret then
         table.insert(filtered, v)
      end
   end

   index = filtered
end

---
---   Server side expansion of URLs
---
if expansion_depth > 0 and expansion_depth ~= keyword_expansion_depth then
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
