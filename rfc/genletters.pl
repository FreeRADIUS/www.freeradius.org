#!/usr/bin/env perl

while (<>) {
    /(rfc\d+)\s+(.*)/;

    $rfc = $1;
    $name = $2;

    next if ($name =~ /\s/);

    $ref{$name} = $rfc;
}

$letter = '';

#
#  Print out the headers
#
foreach (sort {$a cmp $b} keys %ref) {

    $first = substr $_, 0, 1;

    if ($first ne $letter) {
	print "<A HREF=\"#$first\">$first</A>\n";
	$letter = $first
    }
}

foreach (sort {$a cmp $b} keys %ref) {

    $first = substr $_, 0, 1;

    if ($first ne $letter) {
	if ($letter ne '') {
	    print "</UL>\n\n";
	}

	print "<H3><A NAME=\"$first\">$first</A>\n";
	print "\n<UL>\n";
	$letter = $first
    }

    print "<A NAME=\"$_\"></A><A HREF=\"$ref{$_}.html#$_\">$_</A><BR />\n";
}
