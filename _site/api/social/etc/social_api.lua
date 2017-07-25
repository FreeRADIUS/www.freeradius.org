local config = {}

config.under_test = not not os.getenv('TEST_DATA')

config.twitter = {}
config.twitter.consumer_key           = ""
config.twitter.consumer_secret        = ""
config.twitter.access_token           = ""
config.twitter.access_token_secret    = ""

config.github = {}
config.github.host                    = "api.github.com"
config.github.port                    = 443
config.github.ssl                     = true
config.github.path                    = "/repos/FreeRADIUS/freeradius-server/commits"
config.github.cache_exp               = 5

config.github.user                    = "arr2036"
config.github.access_token            = "af72253af896d07f8becb63abc5c8412a1943ee4"

config.stackoverflow = {}
config.stackoverflow.host             = "api.stackexchange.com"
config.stackoverflow.port             = 443
config.stackoverflow.ssl              = true
config.stackoverflow.path             = "/2.2/questions"
config.stackoverflow.cache_exp        = 60
config.stackoverflow.key              = "Pv)MLDFfh)Uh7lqVRL*fmQ(("

return config
