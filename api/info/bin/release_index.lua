local cjson             = require "cjson"
local ngx               = require "ngx"

local helper            = require "lib.helper"
local validate          = require "lib.validate"
local indexer           = require "lib.indexer"

local uri               = ngx.var.uri

local get_args          = ngx.req.get_uri_args()
local sane_args

local releases            = {}
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
                                            { 'name', 'description', 'branch', 'category' })
if err then
   helper.fatal_error(search, err)
end

--[[Function: version_to_int
Convert version string into an integer for comparison

@param version to process.
@return integer representing version or nil
--]]
local function version_to_int(version)
   local m, err = ngx.re.match(version, "^([0-9]{1,2})\\.([0-9]{1,2})\\.([0-9]{1,2}|x)(?:-(pre|beta|alpha)([0-9]{1,2}))?$", "jo")
   local int = 0
   local w = 4

   if err or not m then
      ngx.log(ngx.ERR, err or "Bad version " .. version)
      return nil
   end

   -- Need 5 bytes

   int = (tonumber(m[1]) * (2 ^ 28))            -- A nibble for major
   int = (tonumber(m[2]) * (2 ^ 24)) + int      -- A nibble for minor

   -- x is the HEAD version for a particular branch
   if m[3] == 'x' then
      int = ((2 ^ 16) - 1) - ((2 ^ 8) - 1)      -- Set release byte to 255 for head
   else
      int = (tonumber(m[3]) * (2 ^ 16)) + int   -- A byte for the release
   end

   if m[4] then
      if m[4] == 'pre' then
         w = 3
      elseif m[4] == 'beta' then
         w = 2
      elseif m[4] == 'alpha' then
         w = 1
      else
         ngx.log(ngx.ERR, "Unknown unstable release type \"" .. m[4] '' "\"")
         return nil
      end
   end

   int = (w * (2 ^ 8)) + int
   if m[5] then
      int = int + tonumber(m[5])   -- 1 byte for the pre/beta/alpha number
   end

   return int
end

--[[Function: version_sort
Sort result by version.

@param a first version.
@param b second version.
@return
   - true if a > b
   - false if a <= b
--]]
local function version_sort(a, b)
   local a_int, b_int

   a_int = version_to_int(a.name)
   if not a_int then
      helper.fatal_error()
   end
   b_int = version_to_int(b.name)
   if not b_int then
      helper.fatal_error()
   end

   return a_int > b_int
end

local branch = uri:match("^" .. helper.config.base_url .. "/branch/([^/]+)/")

local index = indexer.new({}, helper.config.base_url .. "/branch/" .. branch .. "/release", sane_args.expansion_depth)
index:build(helper.config.srv_path .. "/branch/" .. branch .. "/release/")

-- Filter by keyword
ret = search and index:filter(search, sane_args.keyword_expansion_depth)

-- Sort by user specified field or by version
ret = sane_args.order_by and index:sort(sane_args.order_by) or index:sort_with(version_sort)

-- Pagenate
index:pagenate(pagenate_start, pagenate_end)

ngx.say(tostring(index));
