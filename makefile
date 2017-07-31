all:
	jekyll serve & browser-sync start --config bs-config.js
build:
	( cd radiusd/man && make )
	jekyll build
	rm -r _site/api/info/srv
	api/info/build/git-to-json.pl /srv/freeradius-server _site/api/info/srv
publish:
	surge _site
hotel:
	jekyll serve --port $PORT & browser-sync start --config bs-config.js --proxy free-radius.dev
