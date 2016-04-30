local ngx    = require "ngx"
local cjson  = require "cjson"
local lfs    = require "lfs"

local helper = require "lib.helper"

local _m = {} -- Module table

--[[Function: tostring
Return index as a JSON string
--]]
function _m:tostring()
   self:expand()

   -- Lua CJSON doesn't have a way of hinting whether empty tables are arrays or hashes
   return table.getn(self.index) > 0 and cjson.encode(self.index) or "[]"
end

--[[Function: new
Instantiate a new keyword search class

@param url_prefix    e.g. /api/foo
@param depth         to expand index to.
--]]
function _m.new(self, url_prefix, depth)
   self = self or {}   -- create object if user does not provide one

   assert(type(depth) == 'number')

   self.url_prefix = url_prefix
   self.need_depth = depth
   self.done_depth = 0

   setmetatable(self, { __index = _m, __tostring = _m.tostring })

   return self
end

--[[Function: set
Use an index built from something other than a directory listing

@param index to set.
--]]
function _m:set(index)
   self.index = index
end

--[[Function: build
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

@param path       On disk path to search in to files found in path.
@param url_prefix to prepend to the file name.

--]]
function _m:build(path)
   local file

   self.index = {} -- Reset the index

   for file in lfs.dir(path) do
      local attrs, err = lfs.attributes(path .. "/" ..file)

      if not attrs then
         ngx.log(ngx.ERR, err)
         return false, err
      end

      if attrs.mode == "file" then
      	local m, err = ngx.re.match(file, "^(.*)\\.[^.]+?$", "jo")
         local name = m[1]

         table.insert(self.index, { name = name, url = self.url_prefix .. "/" .. name .. "/" })
      end
   end

   return true
end

--[[Function: expand

Expand index to the required depth.

--]]
function _m:expand()
   if self.need_depth <= self.done_depth then
      return
   end

   -- Ref needs to be copied to local table and back again
   -- else updates are lost in some circumstances.
   -- Seems like a bug.
   local work = self.index
   local ret = helper.resolve_urls(work, self.need_depth)
   self.index = work

   if ret ~= ngx.OK then
      helper.fatal_error(ret, "Error retrieving nested object (" .. tostring(ret) .. ")")
   end

   self.done_depth = self.need_depth
end

--[[Function: filter

Only keep entries that match the filter object

@param search        Instance of search to use for filtering.
@param search_exp    How many levels to expand for the search.

--]]
function _m:filter(search, search_depth)
   local searches

   assert(type(search) == 'table')

   -- Who needs type checking
   if search.execute then
      searches = { search }
   else
      searches = search
   end

   for i, v in ipairs(searches) do
      local filter = {}

      assert(type(v) == 'table')
      assert(type(search_depth) == 'number')

      for ii, vv in ipairs(self.index) do
         local to_search

         if search_depth > self.need_depth then
            to_search = helper.table_copy(vv)
         else
            to_search = vv
         end

         if search_depth > self.done_depth then
            local ret = helper.resolve_urls(to_search, search_depth - self.done_depth)
            if ret ~= ngx.OK then
               helper.fatal_error(ret, "Error retrieving nested object (" .. tostring(ret) .. ")")
            end
         end

         local ret, msg = v:execute(to_search)
         if ret == nil then
            helper.fatal_error(ngx.HTTP_BAD_REQUEST, msg)
         elseif ret == true then
            table.insert(filter, vv)
         end
      end

      -- We expanded some entries during the search
      if search_depth > self.done_depth and search_depth <= self.need_depth then
         self.done_depth = search_depth
      end

      self.index = filter
   end
end

--[[Function: sort
Sort table entries lexicographically on specified v

@param v(s) to sort on.
@param desc Sort in descending order.
--]]
function _m:sort(v, desc)
   local vs;

   self:expand()

   if type(v) ~= 'table' then
      vs = { v }
   else
      vs = v
   end

   for k, v in ipairs(vs) do
      if desc then
         table.sort(self.index, function (a, b)
            if not a[v] and not b[v] then
               return false
            end
            if not a[v] then
               return true
            end
            if not b[v] then
               return false
            end

            return a[v] > b[v]
         end)
      else
         table.sort(self.index, function (a, b)
            if not a[v] and not b[v] then
               return true
            end
            if not a[v] then
               return false
            end
            if not b[v] then
               return true
            end

            return a[v] < b[v]
         end)
      end
   end

   return true
end

--[[Function: sort_with
Sort table entries using func

@param v to sort on.
--]]
function _m:sort_with(func)
   self:expand()
   table.sort(self.index, func)
end

--[[Function: pagenate
Get a range of elements from a index and return them in a new index

@param first element in the index
@param last element in the index.
--]]
function _m:pagenate(first, last)
   local sliced = {}
   local i

   if not first and not last then
      return
   end

   for i = first or 1, last or #self.index, 1 do
      sliced[#sliced + 1] = self.index[i]
   end

   self.index = sliced
end

return _m
