local cjson    	      = require "cjson"
local ngx      	      = require "ngx"

local config            = require "etc.social_api"
local provider          = config.stackoverflow
local api_client        = require "lib.api_client"
local helper            = require "lib.helper"
local http              = require "resty.http"

local get_args          = ngx.req.get_uri_args()
local num

local ret, res, err
local json

if not get_args.n then
   num = 3
else
   num = tonumber(get_args.n)
end

--[[ Function: filter

@param out        Where to write the filtered responses.
@param to_filter  Response from GitHub to strip.
--]]
local function filter(out, to_filter)
   local to_embed = {}
   local httpc, res

   to_filter = to_filter.items

   for i, v in ipairs(to_filter) do
      -- Our stripped down version of a stackoverflow question.
      -- It follows same structure, but with unneeded fields
      -- stripped.
      table.insert(out, {
         body           = v.body,
         creation_date  = v.creation_date,
         link           = v.link,
         title          = v.title,
         owner = {
            display_name   = v.owner.display_name,
            link           = v.owner.link,
            profile_image  = v.owner.profile_image
         }
      })

      if v.owner.profile_image and (v.owner.profile_image ~= "") then
         unpack(httpc:parse_uri(v.owner.profile_image))
         table.insert(to_embed, { path = tostring(v.owner.profile_image) })
      end
   end

   if table.getn(to_embed) > 0 then
      httpc = http:new()
      httpc:connect('www.freeradius.org', 80)
      res = httpc:request_pipeline{{ path = 'http://www.freeradius.org/logo.png' }}
   end

   -- Failure here is OK, we just want to insert the images
   -- we managed to retrieve.
   for i, v in ipairs(res) do
      if v.status and v.status == ngx.HTTP_OK and v.status.headers["Content-Type"] then
         out[i].owner.profile_image = "data:" .. v.status.headers["Content-Type"] .. ";base64," .. ngx.base64_encode(v:read_body())
      end
   end
end

-- Request arguments
local request_args = {
   ["site"] = "stackoverflow",
   ["filter"] = "withbody",
   ["tagged"] = { "freeradius", "freeradius2", "freeradius3" },
   ["order"] = "desc",
   ["page"] = 1,
   ["pagesize"] = num,
   ["key"] = provider.key
}

-- Set fixed 'until' so we have static data to test against
if config.under_test then
   request_args["todate"] = 1462060800 -- 2016-05-01
   request_args["sort"] = "creation"
else
   request_args["sort"] = "activity"
end

-- See if we've got a cached result and whether it needs updating
local cache = ngx.shared.social_api_stackoverflow_cache
if not cache then
   ngx.log(ngx.ERR, "Cache not declared.  Declare with 'lua_shared_dict social_api_stackoverflow_cache;' in http {}")
   helper.fatal_error(nil, nil, ngx.HTTP_INTERNAL_SERVER_ERROR, "Cache unavailable")
end

local args_hash = ngx.sha1_bin(table.concat(request_args))

-- If we already have a cached response, use that
json = cache:get(args_hash)
if json then
   ngx.status = ngx.HTTP_OK
   ngx.say(json) -- It's already in string form
   ngx.exit(ngx.OK)
end

local api = api_client:new()

-- Make sure we always get zlib back
api.headers['Accept-Encoding'] = "zlib"

local ret, err = api:connect(provider.host, provider.port, provider.ssl, not config.under_test)
if not ret then
   ngx.log(ngx.ERR, err)
   helper.fatal_error(cache, args_hash,
                      ngx.HTTP_GATEWAY_TIMEOUT, "Error connecting to upstream API")
end

local res, err = api:request(provider.path, request_args)
if not res then
   ngx.log(ngx.ERR, err)
   helper.fatal_error(cache, args_hash,
                      ngx.HTTP_SERVICE_UNAVAILABLE, "Error retrieving data from upstream API")
end

local json, err = api:decode_body()
if not json then
   ngx.log(ngx.ERR, err)
   helper.fatal_error(cache, args_hash,
                      ngx.HTTP_SERVICE_UNAVAILABLE, "Error decoding response from upstream API")
end

-- Process API error from upstream
if res.status ~= ngx.HTTP_OK then
   ngx.log(ngx.ERR, err)
   helper.fatal_error(cache, args_hash,
                      ngx.HTTP_SERVICE_UNAVAILABLE,
                      json.error_message or "Unknown upstream error (" .. res.status ..  ")")
end

ngx.status = res.status

local out = {}

-- Strip out cruft from the response, and capture info about missing fields.
ret, err = pcall(filter, out, json)
if err then
   ngx.log(ngx.ERR, err)
   helper.fatal_error(cache, args_hash,
                      ngx.HTTP_SERVICE_UNAVAILABLE, "Incomplete response from upstream")
end

local encoded = cjson.encode(out)

-- Cache so we reduce the number of hits on GitHub's API
cache:set(args_hash, encoded, provider.cache_exp)
ngx.say(encoded)
