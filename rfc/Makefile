#
# Makefile
#
# Version:	$Id: Makefile,v 1.11 2006/09/21 23:17:42 aland Exp $
#

#
#  Note that "attributes.html" and "index.html" were hacked by hand
#  after running these Makefiles..
#
# $ grep H3 attributes.html | perl -ne 's:<H3>(\w)</H3>:<A HREF="#$1">$1</A> :;print' > attr-refs
# $ cat attributes.html | perl -pe 's:<H3>(\w)</H3>:<H3><A NAME="$1">$1</A></H3>:' > foo
# $ mv foo attributes.html
# $ chmod a+x attributes.html
#
# --- edit to add header/footer, CSS, and attr-refs from above.


RFC	= rfc2548.txt rfc2865.txt rfc2866.txt rfc2867.txt rfc2868.txt \
	  rfc2869.txt rfc3162.txt rfc3576.txt rfc3579.txt rfc3580.txt \
	  rfc4590.txt rfc4818.txt

all:

html: refs
	./rewrite.pl $(RFC)
	./per-rfc.pl $(RFC)
	@touch .rewrite

index.html: html
	./update.sh

refs: $(RFC)
	./genref.pl $(RFC) > refs
	@echo 'rfc2865 Class' >> refs
	@echo 'rfc2865 State' >> refs
	@echo 'rfc4818 Delegated-IPv6-Prefix' >> refs

clean:
	rm -f refs *rfc*.html *~ .rewrite index.html

%.html: %.txt refs
	./rewrite.pl $<
	./per-rfc.pl $<

.PHONY: all clean install html
