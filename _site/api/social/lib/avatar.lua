local ngx    = require "ngx"
local cjson  = require "cjson"
local http   = require "resty.http"
local zlib   = require "zlib"

local _m = {} -- Module table

--[[Function: tostring
Return JSON data as a string
--]]
function _m:tostring()
   return cjson.encode(self.json)
end

--[[Function: new
Instantiate a new API client class
--]]
function _m:new()
   self = self or {}   -- create object if user does not provide one
   setmetatable(self, { __index = _m})

   self.httpc = http.new()
   self.headers = {}
   assert(self.httpc)

   return self
end

--[[Function: set_basic_auth

Sets the username/password and auth type.

This is to support personal access tokens.  It shouldn't be used with actual user accounts.

@param username   to authenticate with.
@param token      to authenticate with.
--]]
function _m:do_basic_auth(username, token)
   assert(username)
   assert(token)

   self.headers.Authorization = "Basic " .. ngx.encode_base64(username .. ":" .. token)
end

--[[Function: connect
Connect to upstream data source

@param host       to connect to.
@param port       to connect to.
@param do_ssl     Whether to start SSL on the connection.
@param verify_ssl Perform basic verification.
@return
   - true on success.
   - false, err on error.
--]]
function _m:connect(host, port, do_ssl, verify_ssl)
   local ret, err
   assert(self.httpc)

   -- Connect to the API server.
   ret, err = self.httpc:connect(host, port)
   if not ret then
      return ngx.HTTP_GATEWAY_TIMEOUT, "Connection failed: " .. err
   end

   -- Start HTTPs
   if do_ssl then
      ret, err = self.httpc:ssl_handshake(nil, host, verify_ssl)
      if not ret then
         return ngx.HTTP_INTERNAL_SERVER_ERROR, "SSL handshaked failed: " .. err
      end
   end

   self.done_connect = ret

   return true
end

--[[Function: request
Send a HTTP GET request to an endpoint

@param path to send request for.
@param args to append to the path (GET args).
@return
   - response object on success.
   - nil, err on error
--]]
function _m:request(path, args)
   local res, err, encoding
   local body

   assert(self.httpc)
   assert(self.done_connect)

   res, err = self.httpc:request({ path = path, query = args, headers = self.headers })
   if not res then
      return nil, err
   end

   body = res:read_body()

   encoding = res.headers["Content-Encoding"]
   if encoding and encoding == 'gzip' then
      local inflate = zlib.inflate()
      body = inflate(body)
   end
   self.response = res
   self.body = body

   return res
end

--[[Function: decode response body as json

@return
   - table representing JSON data on success
   - nil, err on failure.
--]]
function _m:decode_body()
   local json, err = cjson.decode(self.body)
   if not json then
      return nil, err .. self.body
   end

   self.json = json

   return json
end

return _m
