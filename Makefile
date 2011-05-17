#
#  Having checkout out freeradius-www, how do you get the rest of the
#  web stuff, without doing 'wget'?
#
#
#  This makefile is old, and probably shouldn't be used
#
#  $Id: Makefile,v 1.2 2002/06/07 18:05:08 aland Exp $
#
all: faq pam_radius_auth mod_auth_radius radiusd

faq.stamp:
	touch faq.stamp	

faq: faq.stamp
	[ -d faq ] || cvs checkout faq
	[ -d faq ] && cvs update -A -d faq
	cd faq;make

pam_radius_auth.stamp:
	touch pam_radius_auth.stamp

pam_radius_auth: pam_radius_auth.stamp
	[ -d pam_radius_auth ] || cvs checkout pam_radius;mv pam_radius pam_radius_auth
	[ -d pam_radius_auth ] && cvs update -A -d pam_radius_auth

mod_auth_radius.stamp:
	touch mod_auth_radius.stamp

mod_auth_radius: mod_auth_radius.stamp
	[ -d mod_auth_radius ] || cvs checkout mod_auth_radius
	[ -d mod_auth_radius ] && cvs update -A -d mod_auth_radius

radiusd.stamp:
	touch radiusd.stamp

radiusd: radiusd.stamp
	[ -d radiusd ] || cvs checkout radiusd
	[ -d radiusd ] && cvs update -A -d radiusd

.PHONY: push
push:
	git push
	git push github
	ssh freeradius.org@liberty "cd www && git pull origin master:master"
	ssh freeradius.org@www.tr.freeradius.org "cd public_html && git pull origin master:master"
