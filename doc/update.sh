#!/bin/sh

MAN_FILES=$(find ../../git.freeradius.org/man/ -type f -print)

for x in $MAN_FILES; do
	HTML="$(basename $x).html"; \
	man2html < $x > $HTML; \
done
