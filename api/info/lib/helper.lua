local cjson       = require "cjson"
local ngx         = require "ngx"
local lfs         = require "lfs"
local io          = require "io"

local search      = require "lib.keyword"

local helper      = {} -- Module table
helper.config     = require "etc.info_api"

local read_body   = false

--[[Function: get_json_subrequest

@param url to fetch.
@return
   - A HTTP status code, either ngx.OK, or ngx.NGX_ERR
   - On ngx.OK the result of the subrequest decoded as JSON
--]]
function helper.get_json_subrequest(url)
   local cache = ngx.shared.info_api_file_cache
   local local_path

   -- Check if the file cache is enabled
   -- Yes the OS should shadow the data, so the get_files cache probably isn't
   -- necessary, but we want consistent use of the cache when resolving files
   -- internally using sub-requests and retrieving them directly.
   if cache then
      -- Can only cache local files
      if string.find(url, helper.config.base_url) == 0 then
         local_path = string.sub(url, helper.base_len + 1)
         json = cache:get(local_path)
         if json then
            return ngx.OK, json
         end
      end
   else
      ngx.log(ngx.ERR, "Cache not declared.  Declare with 'lua_shared_dict info_api_file_cache;' in http {}")
   end

   -- Apparently we need to do this before calling location capture...
   if read_body == false then
      ngx.req.read_body()
      read_body = true
   end

   -- Make internal request to resolve URLs
   local ret = ngx.location.capture(url, {args = {}})
   if ret.status == ngx.HTTP_NOT_FOUND then
      return ret.status, url
   elseif ret.status ~= ngx.HTTP_OK then
      ngx.log(ngx.ERR, "Subrequest for " .. url .. " failed with code " .. tostring(ret.status))
      return ret.status, url
   end

   -- Decode JSON response
   local json, err = cjson.decode(" " .. ret.body)
   if not json then
      ngx.log(ngx.ERR, "Subrequest for " .. url .. " failed.  Can't decode JSON: " .. err)
      return ngx.NGX_ERR, url
   end

   -- Update the cache
   if cache and local_path then
      cache.set(local_path, json)
   end

   return ngx.OK, json
end

--[[Function: resolve_urls

Produces aggregated output to return to the client.

Whenever a table with a URL element is found, the URL is fetched with a subrequest,
the keys in the existing table are moved, and the retponse from the subrequest is inserted.

@note Not idempotent.  Input table will be left in a possibly mangled state on failure.

@param json The result of the data from the previous GET operation.
@param depth   The maximum number of times we recurse to resolve additional URL keys.
@return an ngx.NGX_* code

--]]
function helper.resolve_urls(json, depth)
   local k, v
   local ret, sub

   -- Table with a URL field
   if depth > 0 and json["url"] ~= nil then

      -- Send a sub-request to ourselves (or another site hosted on the same server)
      ret, sub = helper.get_json_subrequest(json["url"])
      if ret ~= ngx.OK then
         return ret, sub
      end

      -- Clear out the old table entries
      for k, v in pairs(json) do
         json[k] = nil
      end

      -- Insert our decoded ones
      for k, v in pairs(sub) do
          json[k] = v
      end

      depth = (depth - 1)
      if depth == 0 then
         return ngx.OK
      end
   end

   -- Recurse to deal with tables
   for k, v in pairs(json) do
      if type(v) == 'table' then
         ret, sub = helper.resolve_urls(v, depth)
         if ret ~= ngx.OK then
            return ret, sub
         end
      end
   end

   return ngx.OK, json
end

--[[Function: get_json_file
Return the contents of a file

@param file to open
@return
   - A HTTP status code, either ngx.OK, or ngx.NGX_ERR
   - On ngx.OK the result of the subrequest decoded as JSON
--]]
function helper.get_json_file(file)
   local cache = ngx.shared.info_api_file_cache
   local content, cached = false

   -- First check the file cache
   if cache then
      content = cache:get(file)
      cached = true
   else
      ngx.log(ngx.ERR, "Cache not declared.  Declare with 'lua_shared_dict info_api_file_cache;' in http {}")
   end

   -- Otherwise we need to populate the cache
   if not content then
      local fandle, err = io.open(file, "r")
      if not fandle then
         return ngx.HTTP_NOT_FOUND
      end

      content = fandle:read("*a")
      fandle:close()
   end

   local json, err = cjson.decode(content)
   if not json then
      ngx.log(ngx.ERR, "Decoding " .. file .. " as json failed: " .. err)
      return ngx.NGX_ERR
   end

   -- Now we know the content is good, populate the cache
   if cache and not cached then
      cache:set(file, content, helper.config.file_cache_exp)
   end

   return ngx.OK, json
end

--[[Function: table_copy
Perform a deep copy on a table_including metadata

@param table to copy.
@return copied table.
--]]
function helper.table_copy(table)
    local table_type = type(table)
    local copy
    local table_key, table_value

    if table_type == 'table' then
        copy = {}
        for table_key, table_value in next, table, nil do
            copy[helper.table_copy(table_key)] = helper.table_copy(table_value)
        end
        setmetatable(copy, helper.table_copy(getmetatable(table)))
    else -- number, string, boolean, etc
        copy = table
    end
    return copy
end

--[[Function: split
Split a string into a table of components

@param string to split
@param pattern to split on
@return table of components split on pattern
--]]
function helper.split(str, pat)
   local t = {}
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)

   while s do
      if s ~= 1 or cap ~= "" then
         table.insert(t,cap)
      end

      last_end = e + 1
      s, e, cap = str:find(fpat, last_end)
   end

   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end

   return t
end

--[[Function: search_from_args
Factory for search class.

@param pattern to search for.
@param fields to search in.
@param default fields to use.
--]]
function helper.search_from_args(patterns, fields, dflt_fields)
   local k, v
   local out = {}

   if not patterns then
      return nil
   end

   for k, v in ipairs(patterns) do
      local search = search.new()

      -- Get the list of keywords we're going to search for
      if fields and fields[k] then
         local ret, err = search:set_fields(fields[k])
         if ret == false then
            return ngx.HTTP_BAD_REQUEST, err
         end
      else
         assert(dflt_fields and (table.getn(dflt_fields) > 0))
         search:set_fields(dflt_fields)
      end

      -- Set and validate the keyword pattern
      local ret, err = search:set_pattern(v)
      if ret == false then
         return ngx.HTTP_BAD_REQUEST, err
      end

      table.insert(out, search)
   end

   return out
end

--[[Function: fatal_error
Raise a fatal error and exit.

@note This function does not return.

@param http_code one of the ngx.HTTP_* constants.  Defaults to HTTP_INTERNAL_SERVER_ERROR if nil
@param msg       Defaults to "Internal error" if nil.
--]]
function helper.fatal_error(http_code, msg)
   http_code = http_code or ngx.HTTP_INTERNAL_SERVER_ERROR
   msg = msg or "Internal error"

   if http_code == ngx.HTTP_INTERNAL_SERVER_ERROR then
      ngx.log(ngx.ERR, string.gsub(debug.traceback(), "[\n\r]", ">"))
   end

   ngx.status = http_code
   ngx.say(cjson.encode({ error = msg }))
   ngx.exit(ngx.HTTP_OK)
end

return helper
