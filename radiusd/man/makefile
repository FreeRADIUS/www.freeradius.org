# Set this to where ever the files are located.
# MAN	:= ../../../git.freeradius.org/man
MAN	:= /srv/freeradius-server/man

VPATH	:= $(MAN)/man1:$(MAN)/man5:$(MAN)/man8

FILES	:= $(notdir $(wildcard $(MAN)/man1/*\.1) $(wildcard $(MAN)/man5/*\.5) $(wildcard $(MAN)/man8/*\.8))

TXT	:= $(addsuffix .txt,$(basename $(FILES)))

HTML	:= $(addsuffix .html,$(basename $(FILES)))

BIN	:= $(filter %.1,$(FILES))
BIN	+= $(filter %.8,$(FILES))

MODS	:= $(filter rlm_%,$(FILES))

CONFIG	:= $(filter %.5,$(FILES))
CONFIG	:= $(filter-out rlm_%,$(CONFIG))


BIN	:= $(sort $(BIN))
MODS	:= $(sort $(MODS))
CONFIG	:= $(sort $(CONFIG))

%.txt:%.1 makefile
	nroff -man -Tascii $< | col -b > $@

%.txt:%.5 makefile
	nroff -man -Tascii $< | col -b > $@

%.txt:%.8 makefile
	nroff -man -Tascii $< | col -b > $@

SED_FIX = '/^<!DOCTYPE/d;/<HTML>/d;s/\.[0-8]\.html"/.html"/g;s,^.*<BODY>.*,<div class="wrapper base_padding_v">,;s,</BODY>,</div>,;s,<A HREF="../man[0-8]/,<a href=",;s,<A HREF="/cgi-bin/man/man2html">man2html</A>,man2html,;s,%,\&percnt;,g;s,\.\./index.html,/man/,'

%.html:%.1 makefile
	echo "---" > $@
	echo "layout: default" >> $@
	echo "---" >> $@
	man2html -r $< | tail -n +2 | sed $(SED_FIX) >> $@

%.html:%.5 makefile
	echo "---" > $@
	echo "layout: default" >> $@
	echo "---" >> $@
	man2html -r $< | tail -n +2 | sed $(SED_FIX) >> $@

%.html:%.8 makefile
	echo "---" > $@
	echo "layout: default" >> $@
	echo "---" >> $@
	man2html -r $< | tail -n +2 | sed $(SED_FIX) >> $@

.PHONY: all
all:	$(TXT) $(HTML) index.html

index.html: $(HTML) programs-inc.html config-inc.html modules-inc.html
	@touch $@

programs-inc.html:
	echo "<ul>" >> $@
	for x in $(BIN); do \
		name=`echo $$x | sed 's,\..*,,'`; \
		echo "<a href=\"$$name.html\">$$name</a>&nbsp;(<a href=\"$$name.txt\">txt</a>)<br />" >> $@; \
	done	
	echo "</ul>" >> $@

config-inc.html:
	echo "<ul>" >> $@
	for x in $(CONFIG); do \
		name=`echo $$x | sed 's,\..*,,'`; \
		echo "<a href=\"$$name.html\">$$name</a>&nbsp;(<a href=\"$$name.txt\">txt</a>)<br />" >> $@; \
	done	
	echo "</ul>" >> $@
	echo >> $@

modules-inc.html:
	echo "<ul>" >> $@
	for x in $(MODS); do \
		name=`echo $$x | sed 's,\..*,,'`; \
		echo "<a href=\"$$name.html\">$$name</a>&nbsp;(<a href=\"$$name.txt\">txt</a>)<br />" >> $@; \
	done	
	echo "</ul>" >> $@

clean:
	@rm -f programs-inc.html config-inc.html modules-inc.html \
		$(TXT) $(HTML)
