#!/usr/bin/env perl
foreach $file (@ARGV) {
    open FILE, "<$file" || die "Error opening $file: $!\n";

    $ref = $file;
    $ref =~ s/\..*//g;

    while (<FILE>) {
	next if (!/^(\d+\.)+\s+([a-zA-Z]+-)+[a-zA-Z]/);
	next if (/,/);

	chop;
	s/^.*?\s+//;

	next if (defined($file{$_}));

	print $ref, "\t", $_, "\n";

	$file{$_} = $ref;
    }

    close FILE;
}
