local cjson  = require "cjson"
local ngx    = require "ngx"
local lfs    = require "lfs"
local io     = require "io"
local utf8   = require "lib.utf8_validator"

local common = {} -- Module table

local read_body = false

if os.getenv('TEST_DATA') then
   common.under_test	       = true
   common.srv_path             = os.getenv('TEST_DATA')
else
   common.srv_path             = ngx.var.document_root .. "/api/info/srv"
end

common.base_url                = "/api/info"
common.file_cache_exp          = 300 * 1000      -- 5 Minute file cache
common.keyword_search_max_len  = 256

-- Configuration cache
common.base_url_len = string.len(common.base_url) -- Don't edit manually

function common.get_last_error()
   local err = last_error
   last_error = nil
   return err
end

--[[Function: common_get_args
Validates get_args common to most pages

@param get_args Table of get_args
@return rcode, msg, expansion_depth, pagenate_start, pagenate_end
--]]
function common.common_get_args(get_args)
   local expansion_depth, keyword_expansion_depth, pagenate_end, pagenate_start

   if get_args.expansion_depth then
      expansion_depth = tonumber(get_args.expansion_depth)
      if not expansion_depth or expansion_depth < 0 then
         return ngx.HTTP_BAD_REQUEST, 'expansion_depth must be a positive integer'
      end
   else
      expansion_depth = 0
   end

   if get_args.keyword_expansion_depth then
      keyword_expansion_depth = tonumber(get_args.keyword_expansion_depth)
      if not keyword_expansion_depth or keyword_expansion_depth < 0 then
         return ngx.HTTP_BAD_REQUEST, 'keyword_expansion_depth must be a positive integer'
      end
   else
      keyword_expansion_depth = 0
   end

   if get_args.pagenate_start then
      pagenate_start = tonumber(get_args.pagenate_start)
      if not pagenate_start or pagenate_start < 0 then
         return ngx.HTTP_BAD_REQUEST, 'pagenate_start must be a positive integer'
      end
      pagenate_start = pagenate_start + 1
   end

   if get_args.pagenate_end then
      pagenate_end = tonumber(get_args.pagenate_end)
      if not pagenate_end or pagenate_end < 0 then
         return ngx.HTTP_BAD_REQUEST, 'pagenate_end must be a positive integer'
      end
      pagenate_end = pagenate_end + 1
   end

   return ngx.OK, "OK", expansion_depth, keyword_expansion_depth, pagenate_start, pagenate_end
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

--[[Function: get_json_subrequest

@param url to fetch.
@return
   - A HTTP status code, either ngx.OK, or ngx.NGX_ERR
   - On ngx.OK the result of the subrequest decoded as JSON
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
      if string.find(url, common.base_url) == 0 then
         local_path = string.sub(url, common.base_len + 1)
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
   local ret = ngx.location.capture(url, {args = {expansion_depth = 0}})
   if ret.status == ngx.HTTP_NOT_FOUND then
      return ret.status
   elseif ret.status ~= ngx.HTTP_OK then
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
@param expansion_depth   The maximum number of times we recurse to resolve additional URL keys.
@return an ngx.NGX_* code

--]]
function common.resolve_urls(json_index, expansion_depth)
   local k, v
   local ret, json

   -- Table with a URL field
   if expansion_depth > 0 and json_index["url"] ~= nil then
      -- Send a sub-request to ourselves (or another site hosted on the same server)
      ret, json = common.get_json_subrequest(json_index["url"])
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

      expansion_depth = (expansion_depth - 1)
      if expansion_depth == 0 then
         return ngx.OK
      end
   end

   -- Recurse to deal with tables
   for k, v in pairs(json_index) do
      if type(v) == "table" then
         ret = common.resolve_urls(v, expansion_depth)
         if ret ~= ngx.OK then
            return ret
         end
      end
   end

   return ngx.OK
end

--[[Function: keyword_search_regex
Case insensitive match using libpcre.
--]]
function keyword_search_regex(value, pattern)
   return not not ngx.re.find(value, pattern, "jio")
end

--[[Function: keyword_search_find
Case sensitive match using Lua's pattern matching
--]]
function keyword_search_find(value, pattern)
   return not not string.find(value, pattern)
end

--[[Function: keyword_search
Pattern match on fields

@param json       object to search (recursively).
@param fields     Array of fields to search.
@param type       Pattern matching function to use, 'regex', 'match' or 'substr'.
@return
   - false no match.
   - true match.
   - nil, msg - on error.
--]]
function common.keyword_search(json, func, pattern, fields)
   local k, v

	assert(json)
	assert(func)
	assert(pattern)

   -- Check for default fields at this level
   for k, v in ipairs(fields) do
      if json[v] ~= nil and type(json[v]) == "string" then
         local ret, err = func(json[v], pattern, ctx)
         if ret == nil then
            return nil, err
         elseif ret == true then
            return true
         end
      end
   end

   -- Recurse to deal with tables
   for k, v in pairs(json) do
      if type(v) == "table" then
         local ret, err = common.keyword_search(v, func, pattern, fields)
         if ret == nil then
            return nil, err
         elseif ret == true then
            return true
         end
      end
   end

   return false
end

--[[Function: keyword_validate
Check that the pattern is valid, producing a end-user friendly error message if not

@param pattern to check
@return
   - nil, err - on error.
   - match func, trimmed pattern on success.
--]]
function common.keyword_validate(pattern)
   local op, pattern_type, func, trim

   -- Protect against obvious fuzzing
   if not utf8.validate(pattern) or string.len(pattern) > common.keyword_search_max_len then
      ngx.log(ngx.INFO, "Client sent invalid keyword string")
      return nil
   end

   -- Figure out what type of pattern this is
   op = string.find(pattern, ':')
   if op ~= nil and op > 0 then
      -- Determine what filter we'll be using to search
      pattern_type = string.sub(pattern, 0, op - 1)
   end

   -- Lua pattern type
   if pattern_type == 'lua' then
      local ret, err
      pattern = string.sub(pattern, op + 1)
      ret, err = pcall(string.find, pattern , pattern)
      if not ret and err then
         err = err:gsub("^%l", string.upper)
         return nil, err
      end

      return keyword_search_find, pattern
   end

   -- Regex pattern type
   if pattern_type == 'regex' then
      pattern = string.sub(pattern, op + 1)
   end

   local from, to , err = ngx.re.find("", pattern, "jio")
   -- Make error more end-user friendly...
   if err then
      err = err:match("^.+failed: (.+)")
      err = err:gsub("^%l", string.upper)

      return nil, err
   end

   return keyword_search_regex, pattern
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

   for file in lfs.dir(path) do
      local attrs, err = lfs.attributes(path .. "/" ..file)

      if not attrs then
         ngx.log(ngx.ERR, err)
         return nil
      end

      if attrs.mode == "file" then
      	local m, err = ngx.re.match(file, "^(.*)\\.[^.]+?$", "jo")
         local name = m[1]

         table.insert(index, { name = name, url = base_url .. "/" .. name .. "/" })
      end
   end

   return index
end

--[[Function: get_json_file
Return the contents of a file

@param file to open
@return
   - A HTTP status code, either ngx.OK, or ngx.NGX_ERR
   - On ngx.OK the result of the subrequest decoded as JSON
--]]
function common.get_json_file(file)
   local err
   local cache = ngx.shared.info_api_file_cache
   local content, cached = false
   local json

   -- First check the file cache
   if cache then
      content = cache:get(file)
      cached = true
   else
      ngx.log(ngx.ERR, "Cache not declared.  Declare with 'lua_shared_dict info_api_file_cache;' in http {}")
   end

   -- Otherwise we need to populate the cache
   if not content then
      fandle, err = io.open(file, "r")
      if not fandle then
         return ngx.HTTP_NOT_FOUND
      end

      content = fandle:read("*a")
      fandle:close()
   end

   json, err = cjson.decode(content)
   if not json then
      ngx.log(ngx.ERR, "Decoding " .. file .. " as json failed: " .. err)
      return ngx.NGX_ERR
   end

   -- Now we know the content is good, populate the cache
   if cache and not cached then
      cache:set(file, content)
   end

   return ngx.OK, json
end

--[[Function: version_to_int
Convert version string into an integer for comparison

@param version to process.
@return integer representing version or nil
--]]
function common.version_to_int(version)
	   local m, err = ngx.re.match(version, "^([0-9]{1,2})\\.([0-9]{1,2})\\.([0-9]{1,2})(?:-(pre|beta|alpha)([0-9]{1,2}))?$", "jo")
		local int = 0
		local w = 4

		if err or not m then
			ngx.log(ngx.ERR, err or "Bad version " .. version)
			return nil
		end

		-- Need 5 bytes

		int = (tonumber(m[1]) * (2 ^ 4))
		int = (tonumber(m[2]) * (2 ^ 3)) + int
		int = (tonumber(m[3]) * (2 ^ 2)) + int

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

		int = (w * 2) + int
		if m[5] then
			int = int + tonumber(m[5])
		end

		return int
end

--[[Function: table_copy
Perform a deep copy on a table_including metadata

@param table to copy.
@return copied table.
--]]
function common.table_copy(table)
    local table_type = type(table)
    local copy
    local table_key, table_value

    if table_type == 'table' then
        copy = {}
        for table_key, table_value in next, table, nil do
            copy[common.table_copy(table_key)] = common.table_copy(table_value)
        end
        setmetatable(copy, common.table_copy(getmetatable(table)))
    else -- number, string, boolean, etc
        copy = table
    end
    return copy
end

--[[Function: fatal_error
Raise a fatal error and exit.

@note This function does not return.

@param http_code one of the ngx.HTTP_* constants.  Defaults to HTTP_INTERNAL_SERVER_ERROR if nil
@param msg       Defaults to "Internal error" if nil.
--]]
function common.fatal_error(http_code, msg)
   http_code = http_code or ngx.HTTP_INTERNAL_SERVER_ERROR
   msg = msg or "Internal error"

   ngx.status = http_code
   ngx.say(cjson.encode({ error = msg }))
   ngx.exit(ngx.HTTP_OK)
end

return common
