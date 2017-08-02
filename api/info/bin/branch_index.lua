-- branch_index.lua
--
-- called with URLs exactly matching
--   /api/info/branch/
--
-- reads all branches in /api/info/srv/branch/*.json
--
local cjson             = require "cjson"
local ngx               = require "ngx"

local helper            = require "lib.helper"
local validate          = require "lib.validate"
local indexer           = require "lib.indexer"

local get_args          = ngx.req.get_uri_args()
local sane_args         = {}

local ret, err

-- Process helper arguments
sane_args, err = validate.get_args(get_args)
if not sane_args then
   helper.fatal_error(ngx.HTTP_BAD_REQUEST, err)
end

sane_args, err = validate.get_args_keyword(get_args, sane_args)
if not sane_args then
   helper.fatal_error(ngx.HTTP_BAD_REQUEST, err)
end

ret, err = validate.get_args_unknown(get_args)
if not ret then
   helper.fatal_error(ngx.HTTP_BAD_REQUEST, err)
end

local search, err = helper.search_from_args(sane_args.by_keyword,
                                            sane_args.keyword_field,
                                            { 'name', 'description', 'start', 'end' })
if err then
   helper.fatal_error(search, err)
end

local index = indexer.new({}, helper.config.base_url .. "/branch", sane_args.expansion_depth)

index:build(helper.config.srv_path .. "/branch/")

-- Filter by keyword
ret = search and index:filter(search, sane_args.keyword_expansion_depth)

-- Sort by user specified field or name
ret = sane_args.order_by and index:sort(sane_args.order_by) or index:sort('name')

-- Pagenate
index:pagenate(pagenate_start, pagenate_end)

ngx.say(tostring(index));
