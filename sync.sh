#!/bin/sh
#
# Sync the main page here
# probably not to be used
#
rsync -i -av -e "ssh -l freeradius.org" prohosted.suntel.com.tr:public_html/ .
