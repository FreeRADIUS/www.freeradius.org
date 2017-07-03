local cjson       = require "cjson"
local ngx         = require "ngx"

local _m          = {} -- Module table


--[[Function: fatal_error
Raise a fatal error and exit.

@note This function does not return.

@param cache      To retrieve previous response from.
@param key        For data in the cache.
@param http_code  one of the ngx.HTTP_* constants.  Defaults to HTTP_INTERNAL_SERVER_ERROR if nil
@param msg        Defaults to "Internal error" if nil.
--]]
function _m.fatal_error(cache, key, http_code, msg)
   if cache and key then
      local cached = cache:get_stale(key);
      if cached then
         ngx.status = ngx.HTTP_OK
         ngx.say(cached)
         ngx.exit(ngx.HTTP_OK)
      end
   end

   http_code = http_code or ngx.HTTP_INTERNAL_SERVER_ERROR
   msg = msg or "Internal error"

   if http_code == ngx.HTTP_INTERNAL_SERVER_ERROR then
      ngx.log(ngx.ERR, string.gsub(debug.traceback(), "[\n\r]", ">"))
   end

   ngx.status = http_code
   ngx.say(cjson.encode({ error = msg }))
   ngx.exit(ngx.HTTP_OK)
end


return _m
