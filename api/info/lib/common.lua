local cjson  = require "cjson"
local ngx    = require "ngx"
local lfs    = require "lfs"
local io     = require "io"
local utf8   = require "lib.utf8_validator"

local common = {} -- Module table

local read_body = false

common.srv_path                = "/srv/www/www.freeradius.org/api/info/srv"
common.base_url                = "/api/info"
common.file_cache_exp          = 300 * 1000      -- 5 Minute file cache
common.keyword_search_limit    = 10000
common.keyword_search_interval = 30 * 1000       -- 10,000 complex keyword searches every 30 seconds
common.keyword_search_max_len  = 256

-- Configuration cache
common.base_url_len = strlen(common.base_url) -- Don't edit manually

--[[Function: common_get_args
Validates get_args common to most pages

@param get_args Table of get_args
@return rcode, expansion_depth, pagenate_start, pagenate_end
--]]
function common.common_get_args(get_args)
   -- Check it's a number...
   if get_args.expansion_depth then
      max_nest = tonumber(get_args.expansion_depth)
      if not max_nest then
         return ngx.HTTP_BAD_REQUEST
      end
   end

   if get_args.pagenate_start then
      pagenate_start = tonumber(get_args.pagenate_start)
      if not pagenate_start then
         return ngx.HTTP_BAD_REQUEST
      end
      pagenate_start = pagenate_start + 1
   end

   if get_args.pagenate_end then
      pagenate_end = tonumber(get_args.pagenate_end)
      if not pagenate_end then
         return ngx.HTTP_BAD_REQUEST
      end
      pagenate_end = pagenate_end + 1
   end

   return ngx.OK, expansion_depth, pagenate_start, pagenate_end
end

--[[Function: pagenate
Get a range of elements from a table and return them in a new table

@param table The input table.
@param first index in the table.
@param last index in the table.
@return slice of input table.
--]]
function common.pagenate(table, first, last)
  local sliced = {}

  for i = first or 1, last or #table, 1 do
    sliced[#sliced+1] = table[i]
  end

  return sliced
end

--[[Function: get_json

@param url to fetch.
@return the retult of the subrequest decoded as JSON

--]]
function common.get_json_subrequest(url)
   local cache = ngx.shared.info_api_file_cache
   local local_path
   local json, err

   -- Check if the file cache is enabled
   -- Yes the OS should shadow the data, so the get_files cache probably isn't
   -- necessary, but we want consistent use of the cache when resolving files
   -- internally using sub-requests and retrieving them directly.
   if cache then
      -- Can only cache local files
      if json_index["url"]:strfind(common.base_url) == 0 then
         local_path = json_index["url"]:strsub(common.base_len + 1)
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
   local ret = ngx.location.capture(url)
   if ret.status ~= ngx.HTTP_OK then
      ngx.log(ngx.ERR, "Subrequest for " .. url .. " failed with code " .. tostring(ret.status))
      return ret.status
   end

   -- Decode JSON response
   json, err = cjson.decode(" " .. ret.body)
   if not json then
      ngx.log(ngx.ERR, "Subrequest for " .. url .. " failed.  Can't decode JSON: " .. err)
      return ngx.NGX_ERR
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

@param json_index The result of the data from the previous GET operation.
@param max_nest   The maximum number of times we recurse to resolve additional URL keys.
@return an ngx.NGX_* code

--]]
function common.resolve_urls(json_index, max_nest)
   local k, v
   local ret, json

   if max_nest > 0 and json_index["url"] ~= nil then
      -- Send a sub-request to ourselves (or another site hosted on the same server)
      ret, json = common.get_json(json_index["url"])
      if ret ~= ngx.OK then
         return ret
      end

      -- Clear out the old table entries
      for k, v in pairs(json_index) do
         json_index[k] = nil
      end

      -- Insert our decoded ones
      for k, v in pairs(json) do
          json_index[k] = v
      end

      max_nest = max_nest - 1
   end

   -- Recurse to deal with tables
   for k, v in pairs(json_index) do
      if type(v) == "table" then
         ret = common.resolve_urls(v, max_nest)
         if ret ~= ngx.OK then
            return ret
         end
      end
   end

   return ngx.OK
end

function keyword_search_regex(value, pattern, ctx)

end

function keyword_search_match(value, pattern, ctx)

end

function keyword_search_cond(value, pattern, ctx)

end

function keyword_search_strfind(value, pattern, ctx)

end

function keyword_search_priv(json, fields, pattern, ctx, cmp)

end

-- remember mappings from original table to proxy table
local proxies = setmetatable( {}, { __mode = "k" } )

function readOnly( t )
  if type( t ) == "table" then
    -- check whether we already have a readonly proxy for this table
    local p = proxies[ t ]
    if not p then
      -- create new proxy table for t
      p = setmetatable( {}, {
        __index = function( _, k )
          -- apply `readonly` recursively to field `t[k]`
          return readOnly( t[ k ] )
        end,
        __newindex = function()
          error( "table is readonly", 2 )
        end,
      } )
      proxies[ t ] = p
    end
    return p
  else
    -- non-tables are returned as is
    return t
  end
end

function common.keyword_search(json_index, pattern, dflt_fields)
   local cmp
   local op
   local ctx

   -- Protect against obvious fuzzing
   if not utf8.validate(pattern) or strlen(pattern) > common.keyword_search_max_len then
      ngx.log(ngx.INFO, "Client sent invalid keyword string")
      return ngx.HTTP_BAD_REQIEST
   end

   op = pattern:strfind(':')
   if op and op > 0 then
      local cache = ngx.shared.info_api_cond_rate_limit

      -- Rate limiting for complex searches
      if cache then
         if common.keyword_search_limit > 0 then
            local limit
            limit = cache:incr("limit")
            if not limit then
               local ok, err = cache:set("limit", 0, common.keyword_search_interval)
               if not ok then
                  ngx.log(ngx.ERR, "Error setting limit key: " .. err)
                  return ngx.HTTP_SERVICE_UNAVAILABLE
               end
            else if limit > common.keyword_search_limit then
               ngx.log(ngx.ERR, "Over keyword search limit")
               return ngx.HTTP_SERVICE_UNAVAILABLE
            end
         end
      else
         ngx.log(ngx.ERR, "Cache not declared.  Declare with 'lua_shared_dict info_api_keyword_rate_limit;' in http {}")
      end

      -- Determine what filter we'll be using to search
      op = pattern:substr(0, op - 1)
      -- PCRE regex
      if op == 'regex' then
         cmp = keyword_search_regex
         ctx = {}
      -- Lua match
      else if op == 'match' then
         cmp = keyword_search_match

      -- Lua expression
      else if op == 'expr' then

         -- Lua 5.2
         if _ENV then

         -- Lua 5.1
         else
            local env = {}
            local func_str

            func_str =
[[
   local global, env

   local index_func = function(t, k)
      return global[k]
   end

   local func = function(json)
      global = json
      return not not (]] .. pattern .. [[) end
   end
   -- Allows unqualified attribute access e.g.
   -- category == 'datastore'
   setmetatable(env, {__index = index_func})
   setfenv(func, env)
]]

         end
      else
         cmp = keyword_search_strfind
      end
   end

   if max_nest > 0 and json_index["url"] ~= nil then
      -- Send a sub-request to ourselves (or another site hosted on the same server)
      ret, json = common.get_json(json_index["url"])
      if ret ~= ngx.OK then
         return ret
      end

      -- Clear out the old table entries
      for k, v in pairs(json_index) do
         json_index[k] = nil
      end

      -- Insert our decoded ones
      for k, v in pairs(json) do
          json_index[k] = v
      end

      max_nest = max_nest - 1
   end

   -- Recurse to deal with tables
   for k, v in pairs(json_index) do
      if type(v) == "table" then
         ret = common.resolve_urls(v, max_nest)
         if ret ~= ngx.OK then
            return ret
         end
      end
   end

   return ngx.OK
end

--[[Function: get_files
Return a list of files in a directory

@param path to search
@return array of files
--]]
function common.get_files(path)
   local file
   local out = {}

   for file in lfs.dir(path) do
      local abs = path .. "/" ..file
      local attrs, err = lfs.attributes(abs)

      if not attrs then
         ngx.log(ngx.ERR, err)
         return nil
      end

      if attrs.mode == "file" then
         table.insert(out, abs)
      end
   end

   return out
end

--[[Function: get_index
Return an array of tables in the form

{
   {
      "name" = <filename without extension>
      "url"  = <relative url>
   },
   {
      "name" = <filename without extension>
      "url"  = <relative url>
   }
}

@param path to search
@param base_url to prepend to the file name
@return array of files
--]]
function common.get_index(path, base_url)
   local index = {}

   -- Loop over all the files, decoding them and putting them in our output table
   for i, v in ipairs(common.get_files(path)) do
      local name = v:match("^.+/([^.]+)")
      if name then
         table.insert(index, { name = name, url = base_url .. "/" .. name .. "/" })
      end
   end

   return index
end

--[[Function: get_file
Return the contents of a file

@param file to open
@return contents of the file as decoded JSON
--]]
function common.get_json_file(file)
   local file, err
   local cache = ngx.shared.info_api_file_cache
   local content
   local json

   -- First check the file cache
   if cache then
      content = cache:get(file)
      if content then
         return content
      end
   else
      ngx.log(ngx.ERR, "Cache not declared.  Declare with 'lua_shared_dict info_api_file_cache;' in http {}")
   end

   -- Otherwise we need to populate the cache
   local path = common.srv_path .. '/' .. file
   file, err = io.open(path, "r")
   if not file then
      ngx.log(ngx.ERR, "Failed reading " .. path .. ": " .. err)
      return nil
   end

   content = file:read("*a")
   file:close()

   json, err = cjson.decode(content)
   if not json then
      ngx.log(ngx.ERR, "Decoding " .. path .. " as json failed: " .. err)
      return ngx.NGX_ERR
   end

   if cache then
      cache:set(file, json)
   end

   return json
end

return common
