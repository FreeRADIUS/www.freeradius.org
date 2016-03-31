local cjson  = require "cjson"
local ngx    = require "ngx"
local lfs    = require "lfs"
local io     = require "io"
local common = {}
local read_body = false

common.srv_path = "/srv/www/www.freeradius.org/api/info/srv"
common.base_url = "/api/info"

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
function common.get_json(url)
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

   -- Decode JSON retponse
   local json, err = cjson.decode(" " .. ret.body)
   if not json then
      ngx.log(ngx.ERR, "Subrequest for " .. url .. " failed.  Can't decode JSON: " .. err)
      return ngx.NGX_ERR
   end

   return ngx.OK, json
end

--[[Function: resolve_urls

Produces aggregated output to return to the client.

Whenever a table with a URL element is found, the URL is fetched with a subrequest,
the keys in the existing table are moved, and the retponse from the subrequest is inserted.

@note Not idempotent.  Input table will be left in a possibly mangled state on failure.

@param json_index The retult of the data from the previous GET operation
@param max_nest   The maximum number of times we recurse to resolve additional URL keys
@return an ngx.NGX_* code

--]]
function common.resolve_urls(json_index, max_nest)
   local k, v
   local ret, json

   if max_nest > 0 and json_index["url"] ~= nil then
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

@param path to open
@return contents of the file
--]]
function common.get_file(path)
   local file, err = io.open(path, "r")

   if not file then
      ngx.log(ngx.ERR, "Failed reading " .. path .. ": " .. err)
      return nil
   end

   local content = file:read("*a")
   file:close()

   return content
end

return common
