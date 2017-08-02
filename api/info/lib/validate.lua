local utf8        = require 'lib.utf8'
local ngx         = require 'ngx'
local helper      = require 'lib.helper'

local _m = {}
_m.config         = require 'etc.info_api'

--[[Function: get_args
Validate common get_arguments for most pages

@param get_args Table of get_args
@return
   - nil, msg on error
   - table of sane arguments on success
--]]
function _m.get_args(get_args)
   local out = {}

   if get_args.expansion_depth then
      if type(get_args.keyword_expansion_depth) == 'table' then
         return nil, 'exactly one instance of expansion_depth allowed'
      end

      out.expansion_depth = tonumber(get_args.expansion_depth)
      if not out.expansion_depth or out.expansion_depth < 0 then
         return nil, 'expansion_depth must be a positive integer'
      end

      if out.expansion_depth > _m.config.max_expansion_depth then
         return nil, 'expansion_depth must be between 0-' ..
            tostring(_m.config.max_expansion_depth)
      end

      get_args.expansion_depth = nil
   else
      out.expansion_depth = 0
   end

   if get_args.keyword_expansion_depth then
      if type(get_args.keyword_expansion_depth) == 'table' then
         return nil, 'exactly one instance of keyword_expansion_depth allowed'
      end

      out.keyword_expansion_depth = tonumber(get_args.keyword_expansion_depth)
      if not out.keyword_expansion_depth or out.keyword_expansion_depth < 0 then
         return nil, 'keyword_expansion_depth must be a positive integer'
      end

      if out.keyword_expansion_depth > _m.config.max_expansion_depth then
         return nil, 'keyword_expansion_depth must be between 0-' ..
            tostring(_m.keyword_expansion_depth)
      end

      get_args.keyword_expansion_depth = nil
   else
      out.keyword_expansion_depth = 0
   end

   if get_args.paginate_start then
      if type(get_args.paginate_start) == 'table' then
         return nil, 'exactly one instance of paginate_start allowed'
      end

      out.paginate_start = tonumber(get_args.paginate_start)
      if not out.paginate_start or out.paginate_start < 0 then
         return nil, 'paginate_start must be a positive integer'
      end
      out.paginate_start = out.paginate_start + 1

      get_args.paginate_start = nil
   end

   if get_args.paginate_end then
      if type(get_args.paginate_end) == 'table' then
         return nil, 'exactly one instance of paginate_start allowed'
      end

      out.paginate_end = tonumber(get_args.paginate_end)
      if not out.paginate_end or out.paginate_end < 0 then
         return nil, 'paginate_end must be a positive integer'
      end
      out.paginate_end = out.paginate_end + 1

      get_args.paginate_end = nil
   end

   -- Validate order by
   if get_args.order_by then
      if type(get_args.order_by) ~= 'table' then
         get_args.order_by = { get_args.order_by }
      end

      if table.getn(get_args.order_by) > _m.config.max_order_by then
         return nil, 'too many order_by arguments (> ' .. _m.config.max_order_by .. ')'
      end

      for i, v in ipairs(get_args.order_by) do
         if not ngx.re.find(v, '^[a-z0-9:_.-]+$', 'jio') then
            return nil, 'field names are restricted to [a-zA-Z0-9:_.-]'
         end
      end

      out.order_by = get_args.order_by
      get_args.order_by = nil
   end

   return out
end

--[[Function: get_args_keyword
Process args specific to endpoints that perform keyword filtering

@param get_args   Get arguments
@param out        Previously processed arguments.  Modified in place.
@return sane arguments
--]]
function _m.get_args_keyword(get_args, out)
   -- Strip out any empty strings
   for k, v in pairs(get_args) do
      if v == "" then
         get_args[k] = nil
      end
   end

   if get_args.by_keyword then
      if type(get_args.by_keyword) ~= 'table' then
         get_args.by_keyword = { get_args.by_keyword }
      end

      -- Ensure we don't have too many search patterns
      if table.getn(get_args.by_keyword) > _m.config.max_search_pattern_args then
            return nil, 'too many by_keyword arguments (> ' .. _m.config.max_search_pattern_args .. ')'
      end

      for i, v in ipairs(get_args.by_keyword) do
         if not utf8.validate(v) then
            return nil, 'by_keyword argument is not a valid UTF8 stirng'
         end

         -- Ensure none of the search patterns are too long
         if string.len(v) > _m.config.max_search_pattern_len then
            return nil, 'by_keyword string too long (> ' .. _m.config.max_search_pattern_len .. ')'
         end
      end

      out.by_keyword = get_args.by_keyword
      get_args.by_keyword = nil
   end

   if get_args.keyword_field then
      if type(get_args.keyword_field) ~= 'table' then
         get_args.keyword_field = { get_args.keyword_field }
      end

      if not out.by_keyword then
         return nil, 'keyword_field argument not valid without by_keyword argument'
      end

      local field_num = table.getn(get_args.keyword_field)
      local keyword_num = table.getn(out.by_keyword)

      -- Ensure we don't have more keyword_field args than by_keyword args
      if field_num > keyword_num then
         return nil, field_num .. ' keyword_field vs ' .. keyword_num .. ' by_keyword arguments'
      end

      -- Validate each of the keyword fields
      for i, v in ipairs(get_args.keyword_field) do
         if not utf8.validate(v) then
            return nil, 'keyword_field argument is not a valid UTF8 stirng'
         end

         -- Split keyword fields (and make sure there aren't too many)
         get_args.keyword_field[i] = helper.split(v, ', ?') -- Split on commas
         if table.getn(get_args.keyword_field[i]) > _m.config.max_search_fields then
            return nil, 'too many search fields (> ' .. _m.config.max_search_fields .. ')'
         end

         -- Ensure none of the keyword fields are too long
         for ii, vv in ipairs(get_args.keyword_field[i]) do
            if string.len(vv) > _m.config.max_search_field_len then
               return false, 'search field too long (> ' .. _m.config.max_search_field_len .. ')'
            end
         end
      end

      out.keyword_field = get_args.keyword_field
      get_args.keyword_field = nil
   end

   return out
end

--[[Function: get_args_category
Process args specific to the category index

@param get_args   Get arguments
@param out        Preciously processed arguments. Modified in place.
@return sane arguments
--]]
function _m.get_args_category(get_args, out)
   if get_args.by_category then
      if type(get_args.by_category) == 'table' then
         return nil, 'exactly one instance of by_category allowed'
      end
      if not ngx.re.find(get_args.by_category, '^[a-z-]+$', 'jio') then
         return nil, 'category names are restricted to [a-z-]'
      end

      out.by_category = get_args.by_category
      get_args.by_category = nil
   end

   if get_args.by_dependency_on then
      if type(get_args.by_dependency_on) == 'table' then
         return nil, 'exactly one instance of by_dependency_on allowed'
      end
      if not ngx.re.find(get_args.by_dependency_on, '^[a-z_]+$', 'jio') then
         return nil, 'component names are restricted to [a-z_]'
      end

      out.by_dependency_on = get_args.by_dependency_on
      get_args.by_dependency_on = nil
   end

   return out
end

--[[Function:get_args_unknown
Check to see that all the get arguments were consumed

@param get_args to check.
@return
   - true if no arguments left/
   - false, error if unrecognised get_args were found.
--]]
function _m.get_args_unknown(get_args)
   for k, v in pairs(get_args) do
      return false, 'get argument ' .. k .. '=' .. v .. ' not recognised'
   end

   return true
end

return _m
