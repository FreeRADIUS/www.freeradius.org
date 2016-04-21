local ngx    = require "ngx"
local utf8   = require "lib.utf8_validator"

local _m = {}

_m.max_search_pattern_len = 128
_m.max_search_fields = 5
_m.max_search_field_len = 128

--[[Function: new
Instantiate a new keyword search class
--]]
function _m.new(self)
   self = self or {}   -- create object if user does not provide one
   setmetatable(self, { __index = _m})
   return self
end

--[[Function: keyword_search_regex
Case insensitive jit'd match using libpcre.
--]]
local function keyword_search_regex(value, pattern)
   return not not ngx.re.find(value, pattern, "jio")
end

--[[Function: keyword_search_find
Case sensitive match using Lua's pattern matching
--]]
local function keyword_search_find(value, pattern)
   return not not string.find(value, pattern)
end

--[[Function: keyword_search
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
Check fields look sane and don't exceed configured limits

@param one or path strings to check
@return
   - false, err - on error.
   - true - on success.
--]]
function _m:set_fields(fields)
   if type(fields) ~= 'table' then
      fields = { fields }
   end

   if table.getn(fields) > self.max_search_fields then
      ngx.log(ngx.INFO, "Client attempted to search on " .. table.getn(fields) ..
              "fields.  Max is " .. self.max_search_fields)
      return false, "Too many search fields"
   end

   for k, v in ipairs(fields) do
      assert(type(v) == 'string')

      if not utf8.validate(v) or string.len(v) > self.max_search_field_len then
         ngx.log(ngx.INFO, "Client sent overly long search field \"" .. v .. "\"")
         return false, "Search field too long"
      end
   end

   self.search_fields = fields

   return true
end

--[[Function: set_fields_default
Set fields directly (without validation checks)

@param fields to set.
--]]
function _m:set_fields_default(fields)
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

   -- Protect against obvious fuzzing
   if not utf8.validate(pattern) or string.len(pattern) > self.max_search_pattern_len then
      ngx.log(ngx.INFO, "Client sent invalid keyword string")
      return false, "Bad keyword string"
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

      self.search_func = keyword_search_find
      self.search_pattern = pattern

      return true
   end

   -- Regex pattern type
   if pattern_type == 'regex' then
      pattern = string.sub(pattern, op + 1)
   end

   local from, to, err = ngx.re.find("", pattern, "jio")
   -- Make error more end-user friendly...
   if err then
      err = err:match("^.+failed: (.+)")
      err = err:gsub("^%l", string.upper)

      return false, err
   end

   self.search_func = keyword_search_regex
   self.search_pattern = pattern

   return true
end

return _m
