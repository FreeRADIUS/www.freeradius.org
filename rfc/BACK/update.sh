#!/bin/sh
#
#  This script makes an HTML page from a simple directory listing
#
#
cat >index.html <<EOF
<HTML>
<TITLE>Index of FreeRADIUS.org's RFC site</TITLE>
<BODY>

<H1>Index of FreeRADIUS.org's RFC site</H1>

List of <A HREF="attributes.html">RADIUS attributes</A>
<P>

<PRE>
EOF

#
#  include the message, if any exists
#
if [ -e message ]; then
  cat .message >> index.html
  echo "</PRE>" >> index.html
fi

#
#  for all of the text files, do this
#
for x in *.txt;do
  echo "<A HREF=\"$x\">$x</A>" >> index.html
  if [ -e $x.gz ]; then
    echo "<A HREF=\"$x.gz\">(gzipped)</A>" >> index.html
  fi
  echo "</BR>" >> index.html
done
echo "</BODY></HTML>" >> index.html
