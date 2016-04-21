local cjson             = require "cjson"
local ngx               = require "ngx"

local common            = require "lib.common"
local keyword_search    = require "lib.keyword_search"
local indexer           = require "lib.indexer"

local get_args          = ngx.req.get_uri_args()
local sane_args
local ret, err

-- Process common arguments
if get_args.by_dependency_on and get_args.by_category then
   common.fatal_error(ngx.HTTP_BAD_REQUEST, "by_category and by_dependency_on filters are mutually exclusive")
end

sane_args, err = common.common_get_args(get_args)
if not sane_args then
   common.fatal_error(ngx.HTTP_BAD_REQUEST, err)
end

local search, err = common.search_from_args(get_args.by_keyword,
                                            get_args.keyword_field,
                                            { 'name', 'description', 'branch', 'category' })
if err then
   common.fatal_error(search, err)
end

local index = indexer.new({}, common.base_url .. "/component", sane_args.expansion_depth)

--
--    Filter by dependency
--
if get_args.by_dependency_on then
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

   index:set(json.dependents)
--
--    Filter by category
--
elseif get_args.by_category then
   local category

   index:build(common.srv_path .. "/component/")

   category = keyword_search.new()
   category:set_fields_default('category')

   if not ngx.re.find(get_args.by_category, "^[a-z-]+$", "jio") then
      common.fatal_error(ngx.HTTP_BAD_REQUEST, "Category names are restricted to [a-z-]")
   end

   ret, err = category:set_pattern(get_args.by_category)
   if ret == false then
      common.fatal_error(ngx.HTTP_BAD_REQUEST, err)
   end

   index:filter(category, 1)
---
---   Don't filter
---
else
   index:build(common.srv_path .. "/component/")
end

-- Filter by keyword
ret = search and index:filter(search, sane_args.keyword_expansion_depth)

-- Sort by user specified field
ret = get_args.order_by and index:sort(get_args.order_by)

-- Pagenate
index:pagenate(sane_args.pagenate_start, sane_args.pagenate_end)

ngx.say(tostring(index));
