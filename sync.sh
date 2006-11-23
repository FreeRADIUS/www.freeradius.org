#!/bin/sh
rsync -i -av -e "ssh -l freeradius.org" prohosted.suntel.com.tr:public_html/ .
