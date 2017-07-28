module Jekyll
    require 'json'
    class JSONGenerator < Generator
        def generate(site)

            socialList = {}

            client = Twitter::REST::Client.new do |config|
                config.consumer_key        = "V9r0TUwgivuQHsmS702hVBB6h"
                config.consumer_secret     = "TnBNR4b4Tb5w5COA8BWpY1RrVLWHHwdrmtGnSL2ANdTT5wBDhD"
                config.access_token        = "83314299-kW2VHgIxlMGdID1Sjlaa3eCpywD1bULcYAQqPSb7N"
                config.access_token_secret = "914ZhqAkpw4gqhSVUH4lEM5nrC4vwxxhYOUoo9Rc5Ho4d"
            end

            timeline = client.user_timeline("freeradius", options= {include_rts: true, exclude_replies: true})

            tweets = []
            timeline.take(10).collect do |tweet|
                # The javascript is picky about the time format,
                # so ensure it doesn't change with system settings.
                tweets.push({"created_at": "#{tweet.created_at.strftime('%a %b %d %H:%M:%S %z %Y')}", "text": "#{tweet.text}"})
            end
            # return tweet
            socialList['twitter'] = JSON.parse(JSON.generate(tweets))

            response_so = HTTParty.get('https://api.stackexchange.com//2.2/search/excerpts?pagesize=10&order=desc&sort=activity&tagged=freeradius&site=stackoverflow')
            socialList['stackoverflow'] = JSON.parse(JSON.generate(response_so['items'].first(10)))

            response_gh = HTTParty.get('https://api.github.com/repos/FreeRADIUS/freeradius-server/commits?client_id=37bcc833b50aaa2f8111&client_secret=7dad0b817aa3b8f8bf1aeb18bbf6bc67c1b5a415')
            socialList['github'] = JSON.parse(JSON.generate(response_gh.first(10)))

            File.open("social.json","w") do |f|
                f.write(JSON.pretty_generate(socialList))
            end

        end
    end
end