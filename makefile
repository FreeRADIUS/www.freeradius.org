all:
	jekyll serve & browser-sync start --config bs-config.js
build:
	jekyll build
publish:
	surge _site
hotel:
	jekyll serve --port $PORT & browser-sync start --config bs-config.js --proxy free-radius.dev
