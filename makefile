#
#  For this to work, you will need to do:
#
#	gem install jekyll twitter httparty
#
#
#  Build the static site.  The main web server publishes the _site
#  directory, and not the jekyll source.
#
all: _wwwdata/twitter.json
	@$(MAKE) -C radiusd/man
	@TZ=GMT jekyll build
	@rm -r _site/api/info/srv
	@api/info/build/git-to-json.pl /srv/freeradius-server _site/api/info/srv

.PHONY: _wwwdata/twitter.json
_wwwdata/twitter.json:
	@[ -e $@ ] || git submodule init && git submodule update

#
#  Serve it from a local host.  This should not be the default.
#
serve:
	jekyll serve & browser-sync start --config bs-config.js

publish:
	surge _site

hotel:
	jekyll serve --port $PORT & browser-sync start --config bs-config.js --proxy free-radius.dev
