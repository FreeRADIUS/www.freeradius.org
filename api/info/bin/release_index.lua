local cjson     = require "cjson"
local ngx       = require "ngx"
local common    = require "lib.common"

local uri       = ngx.var.uri
local get_args  = ngx.req.get_uri_args()
local releases	 = {}
local i, v
local high_version_v, high_version = 0
local index

function version_compare(a, b)
	local a_int, b_int

	a_int = common.version_to_int(a.name)
	if not a_int then
		common.fatal_error()
	end
	b_int = common.version_to_int(b.name)
	if not b_int then
		common.fatal_error()
	end

	return a_int > b_int
end

-- Process common arguments
local ret, msg, expansion_depth, keyword_expansion_depth, pagenate_start, pagenate_end = common.common_get_args(get_args)
if ret ~= ngx.OK then
   common.fatal_error(ret, msg)
end

local branch = uri:match("^" .. common.base_url .. "/branch/([^/]+)/")

-- Determine the last release in this branch
index = common.get_index(common.srv_path .. "/branch/" .. branch .. "/release/", common.base_url .. "/branch/" .. branch .. "/release")
table.sort(index, version_compare)

-- Server side expansion of URL fields using subrequests
if expansion_depth and expansion_depth > 0 then
   local ret = common.resolve_urls(index, expansion_depth)
   if ret ~= ngx.OK then
      common.fatal_error(ret, "Error retrieving resource referenced by expansion URL")
   end
end

-- Pagenate last (for stable pagenation)
if pagenate_start or pagenate_end then
   index = common.pagenate(index, pagenate_start, pagenate_end)
end

ngx.say(table.getn(index) > 0 and cjson.encode(index) or "[]");
