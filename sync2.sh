#!/bin/sh
#
#  Sync the web files here to the main web page
#  It's a bit of a hack, because I didn't create theweb site image
#  in a sub directory.
#
#  Use ./sync2.sh -n
#  to see what will be synchronized
#
#  Once mercurial is set up on the main page, we don't need this.
#
rsync $@ -i -av -e "ssh -l freeradius.org" --exclude="*~" --exclude="\.hg*"  --exclude="\.bash*" --exclude="\.ssh*" --exclude="\.emacs*" --exclude="db\.*" . prohosted.suntel.com.tr:public_html/

