-- branch.lua
--
-- called with URLs of the form
--   /api/info/branch/<branch>/
-- e.g.
--   /api/info/branch/3.0.x/
--
-- reads /api/info/srv/branch/<branch>.json
--
-- adds release url with /api/info/branch/<branch>/release/
--
-- adds "last_release" with the latest release from the release url
--   by recursively calling e.g. API /api/info/branch/3.0.x/release/
--
local cjson             = require "cjson"
local ngx               = require "ngx"

local helper            = require "lib.helper"
local validate          = require "lib.validate"

local uri               = ngx.var.uri

local get_args          = ngx.req.get_uri_args()
local sane_args         = {}

local ret, err

-- Process helper arguments
sane_args, err = validate.get_args(get_args)
if not sane_args then
   helper.fatal_error(ngx.HTTP_BAD_REQUEST, err)
end

ret, err = validate.get_args_unknown(get_args)
if not ret then
   helper.fatal_error(ngx.HTTP_BAD_REQUEST, err)
end

local branch = ngx.re.match(uri, "^" .. helper.config.base_url .. "/branch/([^/]+)/", "jo")
branch = branch[1]

local ret, json = helper.get_json_file(helper.config.srv_path .. "/branch/" .. branch .. ".json")
if ret == ngx.HTTP_NOT_FOUND then
   helper.fatal_error(ret, "Branch \"" .. branch .. "\" not found")
elseif ret ~= ngx.OK then
   helper.fatal_error(ret)
end

-- Add link to releases to allow expansion
json.release = { url = helper.config.base_url .. "/branch/" .. branch .. "/release/" }
ret, json.last_release = helper.get_json_subrequest(json.release.url .. "?paginate_start=0&paginate_end=0")
if ret == ngx.HTTP_NOT_FOUND then
   json.last_release = nil
elseif ret ~= ngx.OK then
   helper.fatal_error(ret, "Error retrieving release list")
else
   json.last_release = json.last_release[1]  -- Releases are ordered DESC
end

-- Server side expansion of URL fields using subrequests
if sane_args.expansion_depth and sane_args.expansion_depth > 0 then
   local ret, url = helper.resolve_urls(json, sane_args.expansion_depth)
   if ret ~= ngx.OK then
      helper.fatal_error(ret, "Error retrieving nested object \"" .. url .. "\" (" .. tostring(ret) .. ")")
   end
end

ngx.say(cjson.encode(json));
