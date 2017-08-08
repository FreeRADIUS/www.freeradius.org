local ngx    = require "ngx"

local config = {}

if os.getenv('TEST_DATA') then
   config.under_test           = true
   config.srv_path             = os.getenv('TEST_DATA')
else
   -- config.srv_path             = ngx.var.document_root .. "/api/info/srv"
   config.srv_path             = ngx.var.document_root .. "/../_apidata"
end

config.base_url                = "/api/info"
config.base_url_len            = string.len(config.base_url) -- Don't edit manually
config.file_cache_exp          = 300 * 1000      -- 5 Minute file cache
config.search_max_len          = 256

config.max_expansion_depth     = 4

config.max_search_pattern_args = 5
config.max_search_pattern_len  = 128

config.max_search_fields       = 5
config.max_search_field_len    = 128

config.max_order_by            = 5

return config
