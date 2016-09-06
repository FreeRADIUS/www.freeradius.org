require 'twitter'
require 'httparty'

module Jekyll
  module FreeRadiusSocialFilter

    def get_freeradius_tweets(num)
      client = Twitter::REST::Client.new do |config|
        config.consumer_key        = "V9r0TUwgivuQHsmS702hVBB6h"
        config.consumer_secret     = "TnBNR4b4Tb5w5COA8BWpY1RrVLWHHwdrmtGnSL2ANdTT5wBDhD"
        config.access_token        = "83314299-kW2VHgIxlMGdID1Sjlaa3eCpywD1bULcYAQqPSb7N"
        config.access_token_secret = "914ZhqAkpw4gqhSVUH4lEM5nrC4vwxxhYOUoo9Rc5Ho4d"
      end

      timeline = client.user_timeline("freeradius", options= {include_rts: false, exclude_replies: true})

      return JSON.generate(timeline.first(num))
    end

    def get_freeradius_stackoverflow_questions(num)
      response = HTTParty.get('https://api.stackexchange.com/2.2/search/excerpts?pagesize=10&order=desc&sort=activity&tagged=freeradius&site=stackoverflow&filter=withbody')
      return JSON.generate(response['items'].first(num))
    end

    def get_freeradius_github_commits(num)
      response = HTTParty.get('https://api.github.com/repos/FreeRADIUS/freeradius-server/commits?client_id=37bcc833b50aaa2f8111&client_secret=7dad0b817aa3b8f8bf1aeb18bbf6bc67c1b5a415')
      return JSON.generate(response.first(num))
    end

  end
end

Liquid::Template.register_filter(Jekyll::FreeRadiusSocialFilter)