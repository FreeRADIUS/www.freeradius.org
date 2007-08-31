# Set this to where ever the files are located.
MAN	:= ../../../branch_1_1/man

VPATH	:= $(MAN)/man1:$(MAN)/man5:$(MAN)/man8

FILES	:= $(notdir $(wildcard $(MAN)/man1/*\.1) $(wildcard $(MAN)/man5/*\.5) $(wildcard $(MAN)/man8/*\.8))

TXT	:= $(addsuffix .txt,$(basename $(FILES)))

HTML	:= $(addsuffix .html,$(basename $(FILES)))

BIN	:= $(filter %.1,$(FILES))
BIN	+= $(filter %.8,$(FILES))

MODS	:= $(filter rlm_%,$(FILES))

CONFIG	:= $(filter %.5,$(FILES))
CONFIG	:= $(filter-out rlm_%,$(CONFIG))

%.txt:%.1
	nroff -man -Tascii $< | col -b > $@

%.txt:%.5
	nroff -man -Tascii $< | col -b > $@

%.txt:%.8
	nroff -man -Tascii $< | col -b > $@

%.html:%.1
	man2html -r $< | tail -n +2 > $@

%.html:%.5
	man2html -r $< | tail -n +2 > $@

%.html:%.8
	man2html -r $< | tail -n +2 > $@

.PHONY: all
all:	$(TXT) $(HTML) index.html

index.html: $(HTML) index.html.top index.html.bot
	cat index.html.top > index.html
	echo "<h2>Programs</h2>" >> index.html
	echo "<ul>" >> index.html
	for x in $(BIN); do \
		name=`echo $$x | sed 's,\..*,,'`; \
		echo "<a href=\"$$name.html\">$$name</a><br />" >> index.html; \
	done	
	echo "</ul>" >> index.html
	echo >> index.html
	echo "<h2>Configuration Files</h2>" >> index.html
	echo "<ul>" >> index.html
	for x in $(CONFIG); do \
		name=`echo $$x | sed 's,\..*,,'`; \
		echo "<a href=\"$$name.html\">$$name</a><br />" >> index.html; \
	done	
	echo "</ul>" >> index.html
	echo >> index.html
	echo "<h2>Modules</h2>" >> index.html
	echo "<ul>" >> index.html
	for x in $(MODS); do \
		name=`echo $$x | sed 's,\..*,,'`; \
		echo "<a href=\"$$name.html\">$$name</a><br />" >> index.html; \
	done	
	echo "</ul>" >> index.html
	cat index.html.bot >> index.html
