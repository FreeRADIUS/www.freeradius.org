local ngx    = require "ngx"

local _m = {}

--[[Function: new
Instantiate a new keyword search class
--]]
function _m:new()
   self = self or {}   -- create object if user does not provide one
   setmetatable(self, { __index = _m})
   return self
end

--[[Function: search_regex
Case insensitive jit'd match using libpcre.
--]]
local function search_regex(value, pattern)
   return not not ngx.re.find(value, pattern, "jio")
end

--[[Function: search_find
Case sensitive match using Lua's pattern matching
--]]
local function search_find(value, pattern)
   return not not string.find(value, pattern)
end

--[[Function: search_literal
Case sensitive match string comparisons
--]]
local function search_literal(value, pattern)
   return not not (value == pattern)
end

--[[Function: search
Pattern match on fields

@param json       object to search (recursively).
@return
   - false no match.
   - true match.
   - nil, msg - on error.
--]]
function _m:execute(json)
   local k, v

   assert(self.search_func)
   assert(self.search_fields)
   assert(self.search_pattern)
   assert(self.search_fields and table.getn(self.search_fields) > 0)

   -- Check for fields starting at _m level
   for k, v in ipairs(self.search_fields) do
      if json[v] ~= nil and type(json[v]) == "string" then
         local ret, err = self.search_func(json[v], self.search_pattern)
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
         local ret, err = self:execute(v)
         if ret == nil then
            return nil, err
         elseif ret == true then
            return true
         end
      end
   end

   return false
end

--[[Function: set_fields
Set fields directly (without validation checks)

@param fields to set.
--]]
function _m:set_fields(fields)
   if type(fields) ~= 'table' then
      fields = { fields }
   end

   for k, v in ipairs(fields) do
      assert(type(v) == 'string')
   end

   self.search_fields = fields
end

--[[Function: set_pattern
Check that the pattern is valid, producing a end-user friendly error message if not

@param pattern to set
@return
   - false, err - on error.
   - true on success.
--]]
function _m:set_pattern(pattern)
   local op, pattern_type, func, trim

   if pattern == nil then
      return true
   end

   if type(pattern) ~= 'number' then
      pattern = tostring(pattern)
   end

   -- Figure out what type of pattern _m is
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
         return false, err
      end

      self.search_func = search_find
      self.search_pattern = pattern

      return true
   end

   -- Regex pattern type
   if pattern_type == 'regex' then
      pattern = string.sub(pattern, op + 1)

      local from, to, err = ngx.re.find("", pattern, "jio")
      -- Make error more end-user friendly...
      if err then
         err = err:match("^.+failed: (.+)")
         err = err:gsub("^%l", string.upper)

         return false, err
      end

      self.search_func = search_regex
      self.search_pattern = pattern

      return true
   end

   -- Literal pattern type
   if pattern_type == 'literal' then
        pattern = string.sub(pattern, op + 1)
   end

   self.search_func = search_literal
   self.search_pattern = pattern

   return true
end

return _m
