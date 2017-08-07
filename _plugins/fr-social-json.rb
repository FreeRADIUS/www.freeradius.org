module Jekyll
    require 'twitter'
    require 'httparty'
    require 'json'
    class JSONGenerator < Generator
        def generate(site)

            # Twitter

            twitter_data = JSON.parse(File.read(site.config['source'] + "/_wwwdata/twitter.json"))
            socialList = {}

            client = Twitter::REST::Client.new do |config|
                config.consumer_key = twitter_data['consumer_key']
                config.consumer_secret = twitter_data['consumer_secret']
                config.access_token = twitter_data['access_token']
                config.access_token_secret = twitter_data['access_token_secret']
            end

            timeline = client.user_timeline(twitter_data['timeline_user'], options= {include_rts: true, exclude_replies: true})

            tweets = []
            timeline.take(10).collect do |tweet|
                # The javascript is picky about the time format,
                # so ensure it doesn't change with system settings.
                tweets.push({"created_at": "#{tweet.created_at.strftime('%a %b %d %H:%M:%S %z %Y')}", "text": "#{tweet.text}"})
            end
            socialList['twitter'] = JSON.parse(JSON.generate(tweets))


            # StackExchange / StackOverflow

            sx_data = JSON.parse(File.read(site.config['source'] + "/_wwwdata/stackexchange.json"))
            response_so = HTTParty.get(sx_data['url'])
            socialList['stackoverflow'] = JSON.parse(JSON.generate(response_so['items'].first(10)))


            # GitHub

            github_data = JSON.parse(File.read(site.config['source'] + "/_wwwdata/github.json"))
            response_gh = HTTParty.get(github_data['url'])
            socialList['github'] = JSON.parse(JSON.generate(response_gh.first(10)))

            File.open("social.json","w") do |f|
                f.write(JSON.pretty_generate(socialList))
            end

        end
    end
end
