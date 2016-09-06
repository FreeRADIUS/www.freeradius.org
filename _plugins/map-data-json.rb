require 'json'

module Social
  class Generator < Jekyll::Generator
    def generate(site)

        response_gh = HTTParty.get('https://api.github.com/repos/FreeRADIUS/freeradius-server/commits?client_id=37bcc833b50aaa2f8111&client_secret=7dad0b817aa3b8f8bf1aeb18bbf6bc67c1b5a415')
        site.data['map'] = JSON.parse(JSON.generate(response_gh.first(10)))

    end
  end
end