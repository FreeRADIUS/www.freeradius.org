local cjson    	      = require "cjson"
local ngx      	      = require "ngx"

local config            = require "etc.social_api"
local provider          = config.github
local api_client        = require "lib.api_client"
local helper            = require "lib.helper"

local get_args          = ngx.req.get_uri_args()
local num

local ret, res, err
local json

--[[ Function: filter

@param out        Where to write the filtered responses.
@param to_filter  Response from GitHub to strip.
--]]
local function filter(out, to_filter)
   for i, v in ipairs(to_filter) do
      -- Our stripped down version of a GitHub commit record.
      -- It follows same structure, but with unneeded fields
      -- stripped.
      table.insert(out, {
         commit = {
            author = {
               date        = v.commit.author.date,
               name        = v.commit.author.name
            },
            committer = {
               date        = v.commit.committer.date,
               name        = v.commit.committer.name
            },
            verification = {
               verified    = (v.commit.verification and v.commit.verification.verified) or false,
               reason      = (v.commit.verification and v.commit.verification.reason) or "Information not provided by GitHub"
            }
         },
         author = {
            html_url    = v.author.html_url,
            avatar_url  = v.author.avatar_url
         },
         committer = {
            html_url    = v.committer.html_url,
            avatar_url  = v.committer.avatar_url
         },
         sha         = v.sha,
         html_url    = v.html_url,
         message     = v.message,
         stats       = v.stats,
      })
   end
end

if not get_args.n then
   num = 3
else
   num = tonumber(get_args.n)
end

-- Request arguments
local request_args = {
   ["page"] = 1,
   ["per_page"] = num
}

-- Set fixed 'until' so we have static data to test against
if config.under_test then
   request_args["until"] = "2016-05-01-00:00:00Z"
end

-- See if we've got a cached result and whether it needs updating
local cache = ngx.shared.social_api_github_cache
if not cache then
   ngx.log(ngx.ERR, "Cache not declared.  Declare with 'lua_shared_dict social_api_github_cache;' in http {}")
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

-- Auth using our access_token, gets us higher quota.
api:do_basic_auth(provider.user, provider.access_token)

local ret, err = api:connect(provider.host, provider.port, provider.ssl, not config.under_test)
if not ret then
   helper.fatal_error(cache, args_hash,
                      ngx.HTTP_GATEWAY_TIMEOUT, "Error connecting to upstream API")
end

local res, err = api:request(provider.path, request_args)
if not res then
   helper.fatal_error(cache, args_hash,
                      ngx.HTTP_SERVICE_UNAVAILABLE, "Error retrieving data from upstream API")
end

local json, err = api:decode_body()
if not json then
   helper.fatal_error(cache, args_hash,
                      ngx.HTTP_SERVICE_UNAVAILABLE, "Error decoding response from upstream API")
end

-- Process API error from upstream
if res.status ~= ngx.HTTP_OK then
   helper.fatal_error(cache, args_hash,
                      ngx.HTTP_SERVICE_UNAVAILABLE,
                      json.message or "Unknown upstream error (" .. res.status ..  ")")
end

local out = {}

-- Strip out cruft from the response, and capture info about missing fields.
ret, err = pcall(filter, out, json)
if err then
   helper.fatal_error(cache, args_hash,
                      ngx.HTTP_SERVICE_UNAVAILABLE, "Incomplete response from upstream")
end

ngx.status = res.status

local encoded = cjson.encode(out)

-- Cache so we reduce the number of hits on GitHub's API
cache:set(args_hash, encoded, provider.cache_exp)
ngx.say(encoded)
