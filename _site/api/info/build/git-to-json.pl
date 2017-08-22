#! /usr/bin/perl

#** @file git_modules_to_json.pl
# @brief Build tree of json files for the web site api to read.
#
# Scans the FreeRADIUS git repository for all sorts of goodies and writes it
# out in json files for the lua API to read.
#
# Written in perl to make Arran happy.
#
# @author Matthew Newton
# @date 2017-07-27
#*

use strict;
use Data::Dumper;
use File::Path qw(make_path);
use JSON;
use Git::Repository;


my $RELBRANCHES = [
	{
		# release means find the latest release tag for this branch
		type => "release",
		branch => "3.0.x",
		description => "Latest stable branch",
		status => "stable",
		priority => 1,
		focus => {
			"3.0.15" => "security",
			"3.0.0" => "new features",
		},
	},
	{
		type => "release",
		branch => "2.x.x",
		description => "Old stable branch",
		status => "end of life",
		priority => 2,
		focus => {
			"2.2.10" => "security",
			"2.2.0" => "security",
			"2.1.0" => "new features",
			"2.0.0" => "new features",
		},
	},
	{
		# development means just download this actual branch HEAD
		type => "development",
		branch => "4.0.x",
		description => "Development branch",
		status => "development",
		priority => 3,
		focus => {
			"4.0.x" => "development",
		},
	},

	{
		# obsolete releases are filtered out by the js
		# code so won't display as downloads
		type => "release",
		branch => "1.x.x",
		description => "Obsolete stable branch",
		status => "obsolete",
		focus => {
			"1.1.8" => "security",
			"1.1.0" => "new features",
			"1.0.0" => "new features",
		},
	},
	{
		type => "release",
		branch => "0.x.x",
		description => "Obsolete stable branch",
		status => "obsolete",
		focus => {
			"0.9.3" => "security",
		},
	},
];



if (scalar @ARGV < 2 or scalar @ARGV > 3) {
	print STDERR "Syntax: $0 <git repository> <output dir> [<module doc locations>]\n";
	exit(1);
}

my $gitdir = $ARGV[0];
my $outdir = $ARGV[1];
my $modlocationfile = $ARGV[2];

if (! -d "$gitdir/.git") {
	die "Cannot find git repository '$gitdir'\n";
}

if (! -d $outdir) {
	mkdir "$outdir";
}

if (! -d $outdir) {
	die "Cannot find output directory '$outdir'\n";
}


my $repo = Git::Repository->new( work_tree => $gitdir );

my $mod_docs;

if (defined $modlocationfile) {
	die "unable to read $modlocationfile\n" unless -r $modlocationfile;
	$mod_docs = read_module_doc_location($modlocationfile);
}


# find all release_x_y_z tags and vN.x.x branches
#
my $versions = get_versions($repo);

# assign each release version to branches in RELBRANCHES, so
# we know which version (e.g. 3.0.5) is in which branch (e.g.
# 3.0.x)
#
add_versions_to_branches($RELBRANCHES, $versions);

# find the latest stable release for each branch
#
find_latest_stable_releases($RELBRANCHES, $versions);

# global component repository to store all info about modules
#
my $components = {};

# go through all versions in git and add the modules and
# protocols to the components repository
#
foreach my $version (keys %$versions) {
	get_release_components($repo, $components, $$versions{$version});
}

# go through each component and record the branches it appears in
# we need this because the web site shows the min and max versions a component
# appears in within a branch, not globally. e.g. rahter than "this appeared in
# 2.0.4 and vanished in 3.0.14" it's "it appeared in 2.x.x between 2.0.4 and
# 2.2.10, and in 3.0.x between 3.0.0 and 3.0.14"
#
find_component_branches($components, $RELBRANCHES);

# work out the data needed for the JSON files for the branches and releases
#
foreach my $release (keys %$versions) {
	get_branch_release_data($repo, $components, $$versions{$release});
}

# read and parse readme file data for the components
#
get_readme_files($repo, $components);

# some modules are in v3.0.x, but not in v4. So let's make them not look quite
# so "obsolete" on the web site because v4 isn't released yet.
#
$$components{rlm_preprocess}{readme} = {
	category => "policy",
	summary => "Pre-process the incoming RADIUS request and fix some common problems. Also checks huntgroups and hints.",
};
$$components{rlm_ruby}{readme} = {
	category => "languages",
	summary => "Adds the abiltiy to run embedded ruby scripts.",
};
$$components{rlm_counter}{readme} = {
	category => "policy",
	summary => "Provides a packet counter to track data usage and other values.",
};
$$components{rlm_dynamic_clients}{readme} = {
	category => "datastore",
	summary => "Loads RADIUS clients as needed, rather than when the server starts.",
};
$$components{rlm_smsotp}{readme} = {
	category => "authentication",
	summary => "Extends FreeRADIUS with a SOCKS interface to create and validate One-Time-Passwords.",
};
$$components{rlm_realm}{readme} = {
	category => "policy",
	summary => "Determine where to proxy requests to based on attributes in the request.",
};
$$components{rlm_replicate}{readme} = {
	category => "io",
	summary => "Opens a new socket for each packet, and \"clones\" the incoming packet to the destination realm.",
};
$$components{rlm_eap_tnc}{readme} = {
	category => "authentication",
	summary => "Interfaces with the naeap library to provide the EAP-TNC inner method.",
};
$$components{rlm_ippool}{readme} = {
	category => "policy",
	summary => "Allocates an IPv4 address from a pool stored in a GDBM database.",
};
$$components{rlm_eap_ikev2}{readme} = {
	category => "authentication",
	summary => "Implements the EAP-IKEv2 protocol functionality.",
};
$$components{rlm_otp}{readme} = {
	category => "authentication",
	summary => "One-time password implementation.",
};
$$components{rlm_sql_iodbc}{readme} = {
	category => "datastore",
	summary => "Connect to databases via iODBC.",
};
$$components{proto_dhcp}{readme} = {
	category => "protocols",
	summary => "Implements the DHCP protocol for IPv4. Replaced in v4 by the proto_dhcpv4 module.",
};

# work out the data needed for the components' JSON files
#
foreach my $component (keys %$components) {
	get_component_release_data($repo, $$components{$component}, $mod_docs);
}

# write out a shedload of json files
#
build_web_json($RELBRANCHES, $versions, $components, $outdir);

exit;



#** @function read_module_doc_location ($filename)
# @brief Read JSON file containing module documentation links
#
# @params $filename	JSON file
#
# @retval $moddocs	Hash of module name to URL
#*

sub read_module_doc_location
{
	my $filename = shift;
	local $/;

	return undef unless -r $filename;

	open my $f, "<", $filename;
	$/ = undef;
	my $jsondata = <$f>;
	close $f;

	my $json = JSON->new();
	return $json->decode($jsondata);
}


#** @function component_url ($component)
# @brief Get relative URL for a component
#
# @params $component	Module or protocol name
#
# @retval $url		Relative URL
#*

sub component_url
{
	my $component = shift;

	return "/api/info/component/$component/";
}


#** @function version_compare ($version_a, $version_b)
# @brief Compare two version numbers
#
# Equivalent to perl's "<=>" and "cmp" operators for FreeRADIUS version
# numbers. Given two version numbers (e.g. "3.0.5" and "2.2.8") returns -1, 0
# or 1 depending on whether the first is less than, equal to or greater than
# the second.
#
# @params $version_a	Version number
# @params $version_b	Version number
#
# @retval $cmp		-1, 0 or 1
#*

sub version_compare
{
	my ($va, $vb) = @_;

	# $va and $vb are in the form "1.2.3"
	#
	my @sa = split /\./, $va;
	my @sb = split /\./, $vb;

	# go through each component of the version number, if they are the
	# same then jump to the next, otherwise comparison can stop here.
	#
	for (my $i = 0; $i < 3; $i++) {
		# do a string comparison to see if they're the same
		# (we sometimes have 'x', so not numerical here)
		next if $sa[$i] eq $sb[$i];

		# they're not both 'x', so if one is then it's newer
		return 1 if $sa[$i] eq "x";
		return -1 if $sb[$i] eq "x";

		# must be numbers then, so just do a numerical comparison
		return $sa[$i] <=> $sb[$i];
	}

	# both versions are the same
	#
	return 0;
}


#** @function get_component_readme ($repo, $blob)
# @brief Retrieve component README.md and parse it
#
# Given a git blob of a README.md file, pulls it from the git repository and
# parses it into a usable data structure.
#
# README.md file format is "# module_name" on the first line, followed by
# sections delimited by "## section_name".
#
# @params $repo		Git::Repository reference
# @params $blob		Git blob
#
# @retval $readme	Hash reference of README data
#*

sub get_component_readme
{
	my ($repo, $blob) = @_;
	my $readme = {};

	# read the blob from git
	#
	my $data = $repo->command("show" => $blob)->stdout;
	return undef unless $data;

	my $state = "header";
	my $sectionname;
	my $sectiondata;

	while (my $line = $data->getline()) {
		chomp $line;

		# at the start, look for a header with a module name
		#
		if ($state eq "header") {
			next if ($line =~ /^\s*$/);

			unless ($line =~ /^#\s+([a-z0-9_]+)$/) {
				die "malformed README header '$line'\n";
			}
			$$readme{componentname} = $1;
			$state = "section";
			next;
		}

		if ($state eq "section") {
			if ($line =~ /^##\s+([A-Za-z]+)$/) {
				if ($sectionname) {
					$$readme{lc $sectionname} = $sectiondata;
				}

				$sectionname = $1;
				$sectiondata = "";
				$state = "section";
				next;
			}
		}

		if ($state eq "section") {
			$sectiondata .= "$line\n";
		}
	}

	if ($state eq "section" and $sectionname) {
		$$readme{lc $sectionname} = $sectiondata;
	}

	return $readme;
}


#** @function changelog_entry_components_json ($entry, $components)
# @brief Heuristic to try and work out what components were affected
#
# Scans text for patterns and returns a list of potential components
# in the format required for the releases JSON file.
#
# @params $entry	ChangeLog entry
# @params $%components	Component repository
#
# @retval $components	Some of the components that may have been touched
#*

sub changelog_entry_components_json
{
	my ($entry, $components) = @_;
	my %found_component;
	my @json;

	my %keywords = (
		"couchbase"	=> "rlm_couchbase",
		"memcached"	=> "rlm_cache_memcached",
		"eap"		=> "rlm_eap",
		"ocsp"		=> "rlm_eap",
		"peap"		=> "rlm_eap_peap",
		"ttls"		=> "rlm_eap_ttls",
		"eap-tls"	=> "rlm_eap_tls",
		"linelog"	=> "rlm_linelog",
		"huntgroups"	=> "rlm_preprocess",
		"python"	=> "rlm_python",
		"redis"		=> "rlm_redis",
		"sql"		=> "rlm_sql",
		"postgresql"	=> "rlm_sql_postgresql",
		"sqlite3"	=> "rlm_sql_sqlite",
		"dhcp"		=> "proto_dhcp",
		"vmps"		=> "proto_vmps",
	);


	# quick heuristic scan for modules or protocols that
	# have been mentioned
	#
	if ($entry =~ /\b((?:rlm|proto)_[a-z0-9_]+)\b/) {
		$found_component{$1} = 1;
	}

	# scan for keywords in the above list
	#
	foreach my $kw (keys %keywords) {
		$found_component{$keywords{$kw}} = 1 if $entry =~ /\b$kw\b/i;
	}

	# check components actually exist - otherwise the
	# javascript blows up when the lua returns 404
	# then add to the array used for the json file
	#
	foreach my $component (sort keys %found_component) {
		if (!$$components{$component}) {
			warn "component $component in a changelog not actually found, skipping\n";
			next;
		}
		my $c = {
			name => $component,
			url => component_url($component),
		};
		push @json, $c;
	}

	return \@json;
}


#** @function get_release_changelog ($repo, $blob)
# @brief Retrieve doc/Changelog for a release parse it
#
# Given a git blob of a Changelog file, pulls it from the git
# repository and parses it into a usable data structure.
#
# Changelog file format is header line starting with FreeRADIUS,
# followed by bulleted lists of changes, with possible headers.
# Recent releases are separated in to "Feature improvements" and
# "Bux fixes", but older releases are less standard.
#
# @params $repo		Git::Repository reference
# @params $blob		Git blob
#
# @retval $changelog	Hash reference of Changelog data
#*

sub get_release_changelog
{
	my ($repo, $commit) = @_;
	my $changelog = {};

	# read the blob from git
	#
	my $data = $repo->command("show" => "$commit:doc/ChangeLog")->stdout;
	return undef unless $data;

	my $line = $data->getline(); # get the header line

	if ($line !~ /^FreeRADIUS /) {
		return undef if $commit eq "release_0_1_0";
		# panic, the header isn't as expected
		die "PANIC, $commit ChangeLog header isn't as expected.\n$line\n";
	}

	my $header = "Generic improvements";

	LINES: while ($line = $data->getline()) {
		chomp $line;

		next if $line =~ /^\s*$/;

		# look for header lines (No "*") and change the header
		#
		# grrr, 3.0.8 had a line with 8 spaces instead of a tab, and
		# 2.1.12 had a space followed by a tab, so try and pick up
		# anything here that "looks" like a tab
		#
		if ($line =~ /^ (?:\s{0,7}\t|\s{8}) ([^\*\s].*) \s*$/x) {
			$header = $1;
			$$changelog{$header} = [];

			next;
		}

		# look for items
		#
		if ($line =~ /^ (?:\s{0,7}\t|\s{8}) \* \s+ (.*?) \.? \s*$/x) {
			my $item = $1;

			push @{$$changelog{$header}}, $item;

			next;
		}

		if ($line =~ /^ (?:\s{0,7}\t|\s{8}) \s+ (.*?) \.? \s*$/x) {
			my $item = $1;

			my $list = $$changelog{$header};
			my $lastitem = pop @$list;
			$item = $lastitem . " " . $item;
			push @$list, $item;

			next;
		}

		last LINES if $line =~ /^FreeRADIUS /;
		last LINES if $line =~ /^  -- /;

		# PANIC!
		die "$commit has unexpected Changelog line:\n$line\n";
	}

	return $changelog;
}


#** @function get_versions ($repo)
# @brief Get all release tags and dev branches from the git repository
#
# Scans the git repository for all standard development branches and release
# tags (that begin 'release_') and returns them in a hash where the keys are
# the version number and the values are the release tag and type of branch.
#
# @params $repo		Git::Repository reference
#
# @retval $%versions	Hash reference of version => hashref of branch and type
#*

sub get_versions
{
	my $repo = shift;

	# get all tags
	#
	my @tags = map {chomp $_; $_}
		$repo->command("tag" => '-l')->stdout->getlines();

	# get version number of all tags and put into hash
	#
	my %versions = map {/^release_(\d+)_(\d+)_(\d+)$/ ?
		("$1.$2.$3", {tag => $_, type => "release", version => "$1.$2.$3"}) :
		()} @tags;

	# find all branches, to see what's in development
	#
	my @branches = map {chomp $_; $_}
		$repo->command("branch" => '-a')->stdout->getlines();

	# if the branches are "public facing" ones then add them to the hash
	#
	foreach my $branch (@branches) {
		if ($branch =~ /^[\s\*]+((?:remotes\/origin\/)?v(\d+\.(?:\d+|x)\.x))$/) {
			$versions{$2} = {
				tag => $1,
				type => "development",
				version => $2,
			};
		}
	}

	return \%versions;
}


#** @function version_is_in_branch ($version, $branch)
# @brief Check to see if this version is in this branch
#
# Does the version number match the branch? e.g. 3.0.14 matches branch 3.0.x,
# but does not match 3.1.x or 2.x.x. Basically treat 'x' as a wildcard and
# everything else must match.
#
# @params $version	A FreeRADIUS version number
# @prarms $branch	A FreeRADIUS branch number
#
# @retval $yes		1 if this version is in the branch, else 0
#*

sub version_is_in_branch
{
	my ($version, $branch) = @_;

	# split version and branch into components
	#
	my @vc = split /\./, $version;
	my @bc = split /\./, $branch;

	# go through each component of the version number, if they are the
	# same then jump to the next, otherwise comparison can stop here.
	#
	for (my $i = 0; $i < 3; $i++) {
		# keep going if component is the same
		next if $vc[$i] eq $bc[$i];

		# keep going if branch component is 'x'
		next if $bc[$i] eq "x";

		# version number shoulnd't contain 'x', but may as well to enable
		# comparing branch numbers too
		next if $vc[$i] eq "x";

		# they don't match, and are not 'x'
		return 0;
	}

	# version matches the branch
	#
	return 1;
}


#** @function add_versions_to_branches ($relbranches, $versions)
# @brief Add versions to the release branch hash
#
# Scan through all versions in $versions and assign them to a particular
# branch in $relbranches, if possible.
#
# @params $@relbranches	All branches we're interested in for the web site
# @prarms $%versions	All versions found in the git repository
#*

sub add_versions_to_branches
{
	my ($relbranches, $versions) = @_;

	foreach my $branch (@$relbranches) {
		$$branch{releases} = [];

		foreach my $version (keys %$versions) {
			if (version_is_in_branch($version, $$branch{branch})) {
				push @{$$branch{releases}}, $$versions{$version};
				$$versions{$version}{branch} = $branch;
			}
		}
	}
}


#** @function get_release_components ($repo, $reltag)
# @brief Get all components included in a particular release
#
# Looks at all directories under src/modules in a given release and returns a
# hash of all modules. Key is the module name, and value is a hash with the
# module name, parent module name (e.g. rlm_sql for rlm_sql_sqlite) and readme
# for the module if available.
#
# @params $repo		Git::Repository reference
# @params $versioninfo	Hash reference of tag name and type (devel or release)
#
# @retval $%modules	Hash reference of module name => module information
#*

sub get_release_components
{
	my ($repo, $components, $release) = @_;

	my $version = $$release{version};
	my $reltag = $$release{tag};

	# run git ls-tree to find all subdirectories of src/modules for a
	# particular git tag, and get the data as an array of hashes
	#
	my $trees = $repo->command("ls-tree" => "-rt", "$reltag", "src/modules/")->stdout;
	my @objects = grep {$$_{path} =~ /^src\/modules\// and
				($$_{type} eq "tree" or $$_{path} =~ m+/README.md$+)}
		map {my @x = split /\s+/; {
			mode => $x[0],
			type => $x[1],
			hash => $x[2],
			path => $x[3],
		}}
		$trees->getlines();

	# go through each git object and work out which modules exist
	#
	foreach my $gitobject (@objects) {
		next unless $$gitobject{path} =~ m+^src/modules/+;

		my @nodes = split /\//, $$gitobject{path};

		# get the relevant module name
		#
		my $name;

		if ($$gitobject{type} eq "tree") {
			# the main module name will always be at the end of the path
			# and begin with rlm_ or proto_
			$name = $nodes[$#nodes];
		} else {
			# we only care about README files, so short circuit if not
			next unless $nodes[$#nodes] eq "README.md";
			$name = $nodes[$#nodes-1];
		}

		# only interested in certain directories
		#
		next unless $name =~ /^(rlm|proto)_/;

		# create main component repository entry
		#
		unless (defined $$components{$name}) {
			$$components{$name} = {
				name => $name,
				minrelease => $version,
				maxrelease => $version,
				maxdevrelease => $version,
				branches => {},
				releases => {},
			};
		}

		# shortcut for this component in the main component repository
		#
		my $c = $$components{$name};

		# find the parent for submodules
		#
		if ($$gitobject{type} eq "tree" and $#nodes > 2) {
			my $parent = @nodes[2];

			# sanity check that parents for different versions are the same
			#
			if ($$c{parent} and $$c{parent} ne $parent) {
				die "differing parents for $name";
			}

			# set the parent
			#
			$$c{parent} = $parent;
		}

		# get the module readme
		#
		# don't check for stable/development versions here - see comments below
		#
		if ($$gitobject{type} eq "blob") {
			my $readmeblob = $$gitobject{hash};

			my $oldversion = $$c{readmeversion} || "0.0.0";
			if (version_compare($oldversion, $version) < 0) {
				$$c{readmeblob} = $readmeblob;
				$$c{readmeversion} = $version;
			}
		}

		$$c{releases}{$version} = $release;


		# track minimum and maximum released versions for this module
		#
		# If the version we are comparing is a released version, then
		# that takes all precedence so we only show released versions
		# on the web site (e.g. from version 1.1.0 to 3.0.15, even
		# though the module is also in version 4.0.x under development.
		# However, if the module is *only* in development versions
		# (say, 3.1.x and 4.0.x) then show the minimum and maximum
		# versions of that instead so that the module gets listed.
		#
		# In either case, the README.md is always taken from the very
		# latest development version of the server.
		#
		if ($$release{type} eq "release") {
			if ($$c{minrelease} =~ /x/ or version_compare($$c{minrelease}, $version) > 0) {
				$$c{minrelease} = $version;
			}

			if ($$c{maxrelease} =~ /x/ or version_compare($$c{maxrelease}, $version) < 0) {
				$$c{maxrelease} = $version;
			}
		}
		else {
			if ($$c{minrelease} =~ /x/ and version_compare($$c{minrelease}, $version) > 0) {
				$$c{minrelease} = $version;
			}

			if ($$c{maxrelease} =~ /x/ and version_compare($$c{maxrelease}, $version) < 0) {
				$$c{maxrelease} = $version;
			}
		}

		# track latest development version, just because
		#
		$$c{maxdevrelease} = $version if version_compare($$c{maxdevrelease}, $version) < 0;
	}

	return $components;
}


#** @function find_component_branches ($components, $relbranches)
# @brief Find all branches that a component is included in
#
# Goes through all components and releases that the component is in, and
# adds an entry for each relevant branch.
#
# @params $%components	Component repository
# @params $%relbranches	Branches available
#*

sub find_component_branches
{
	my ($components, $relbranches) = @_;

	# go through all new modules and protocoles and add to the main
	# component repository as required, tracking release numbers
	#
	foreach my $component (keys %$components) {
		my $c = $$components{$component};

		# through all releases this component is included in
		#
		foreach my $release (keys %{$$c{releases}}) {
			# find out which branches the module appears in, and add them
			# to the branches hash
			#
			foreach my $branch (@$relbranches) {
				if (version_is_in_branch($release, $$branch{branch})) {
					$$c{branches}{$$branch{branch}} = $branch;
				}
			}
		}
	}
}


#** @function get_readme_files ($components)
# @brief Retrieve all module README.md files
#
# Goes through the component repository and fetches all the README.md files for
# each module from the git repo. Done here rather than earlier so we only pull
# the latest README for each module. If nothing else, earlier READMEs are
# unlikely to be formatted correctly, and therefore will cause the parse sub to
# blow up.
#
# @params $repo		Git::Repository reference
# @params $%components	Component repository
#
# @retval $%components	Component repository
#*

sub get_readme_files
{
	my ($repo, $components) = @_;

	foreach my $component (keys %$components) {
		my $cd = $$components{$component};
		my $readme;

		# get the readme file data and add to the component
		#
		if (defined $$cd{readmeblob}) {
			$readme = get_component_readme($repo, $$cd{readmeblob});
		} else {
			# module has no useful README to use, it's probably old,
			# so make something up
			#
			$readme = {
				componentname => $$cd{name},
				summary => "The " . $$cd{name} . " module.",
			}
		}

		$$cd{readme} = $readme;

		# If there is some metadata, hope it is fairly well formed and
		# try and extract the category from it. Should be better to use
		# a proper XML library, but whatever.
		#
		if ($$readme{metadata}) {
			my $metadata = $$readme{metadata};

			# strip all whitespace
			$metadata =~ s/\s*//mg;

			# check for something that looks familiar
			if ($metadata =~ m#<dl><dt>category</dt><dd>([a-z]+)</dd>#) {
				$$readme{category} = $1;
			}
		} else {
			$$readme{category} = 'obsolete';
		}
	}
}


#** @function find_latest_stable_releases ($relbranches, $versions)
# @brief Find which versions are the latest in particular branches
#
# Some versions in relbranches may be "stable", but listed as e.g. 3.0.x. This
# will find the latest stable version in that train.
#
# @params $%relbranches	Branches available
# @params $%versions	All git versions and tags
#
# @retval $%relbranches	Updated release versions with branch info
#*

sub find_latest_stable_releases
{
	my ($relbranches, $versions) = @_;

	my $branches = [];

	# check each release version
	#
	foreach my $rv (@$relbranches) {
		my $version = $$rv{branch};

		# while development versions will be the same as listed in
		# relbranches (e.g. 4.0.x is always the HEAD of v4.0.x),
		# released versions will point to the latest dev version in
		# that train and we need find the latest released version
		# instead.
		#
		if ($$rv{type} eq "release" and $version =~ /x/) {
			my $stableversion = "0.0.0";

			# go through versions in order, remembering last stable
			# version number we've seen. quit out if we hit the
			# development version we're looking for.
			#
			foreach my $v (sort {version_compare($a, $b)} keys %$versions) {
				my $version_is_same_or_lower = (
					version_compare($v, $$rv{branch}) != 1
				);

				if ($$versions{$v}{type} eq "release" and
					$version_is_same_or_lower) {
					$stableversion = $v;
				}

				last if not $version_is_same_or_lower;
			}

			# TODO maybe we should check here to make sure the
			# version we searched for and found was actually in the
			# same train, e.g. searching for 8.1.x stable will
			# currently quite happily return release_3_0_15, which
			# probably isn't what is intended.

			$version = $stableversion;
		}

		my $tagname = $$versions{$version}{tag};
		die "unable to find version $version\n" unless defined $tagname;

		$tagname =~ s+^remotes/origin/++; # trim off remotes
		$$rv{latestversion} = $version;
		$$rv{latesttag} = $tagname;
	}

	return $relbranches;
}

sub get_component_release_minmax
{
	my ($branch) = @_;
	my ($min, $max);

	my $releases = $$branch{releases};

	foreach my $release (@$releases) {
		my $version = $$release{version};

		$min = $$release{version} unless defined $min;
		$max = $$release{version} unless defined $max;

		# track minimum and maximum released versions for this module
		#
		# If the version we are comparing is a released version, then
		# that takes all precedence so we only show released versions
		# on the web site (e.g. from version 1.1.0 to 3.0.15, even
		# though the module is also in version 4.0.x under development.
		# However, if the module is *only* in development versions
		# (say, 3.1.x and 4.0.x) then show the minimum and maximum
		# versions of that instead so that the module gets listed.
		#
		# In either case, the README.md is always taken from the very
		# latest development version of the server.
		#
		if ($$release{type} eq "release") {
			if ($min =~ /x/ or version_compare($min, $version) > 0) {
				$min = $version;
			}

			if ($max =~ /x/ or version_compare($max, $version) < 0) {
				$max = $version;
			}
		}
		else {
			if ($min =~ /x/ and version_compare($min, $version) > 0) {
				$min = $version;
			}

			if ($max =~ /x/ and version_compare($max, $version) < 0) {
				$max = $version;
			}
		}
	}

	return ($min, $max);
}


#** @function get_branch_release_data ($repo, $components, $release)
# @brief Build data structure for each release
#
# Pulls together everything needed to create a branch release JSON file.
#
# @params $repo		Git::Repository reference
# @params $%components	Component repository
# @params $%release	Hashref of release
#*

sub get_branch_release_data
{
	my ($repo, $components, $release) = @_;

	my %json;

	my $version = $$release{version};
	my $tag = my $tagname = $$release{tag};
	$tagname =~ s+^remotes/origin/++;

	# find focus of the release
	#
	my $focus = $$release{branch}{focus}{$version} || "stability";

	my $latest = 0;
	$latest = 1 if $$release{branch}{latestversion} eq $version;

	# build download links
	#
	my @download = ();
	my @mirror = ();

	if ($$release{type} eq "release") {
		foreach my $type (qw(tar.gz tar.bz2)) {
			my %d = ( name => $type );

			# release files should be on the freeradius FTP site
			#
			my $path = "ftp://ftp.freeradius.org/pub/freeradius/";

			$path .= "old/" unless $latest;
			$path .= "freeradius-";
			$path .= "server-" unless $version =~ /^[01]\./;

			$path .= "$version.$type";

			$d{url} = $path;
			$d{sig_url} = "$path.sig",

			push @download, \%d;

			if ($type eq "tar.gz") {
				# github supports tar.gz and zip, so we can't do tar.bz2 here
				push @mirror, {
					name => "GitHub ($type)",
					url => "https://github.com/FreeRADIUS/freeradius-server/archive/$tagname.$type",
				};
			}

		}
	} else {
		foreach my $type (qw(tar.gz)) {
			my %d = ( name => $type );

			# whatever it is, github should have it...
			#
			$d{url} = "https://github.com/FreeRADIUS/freeradius-server/archive/$tagname.$type",
			# ...but has no .sig

			push @download, \%d;
		}
	}

	$json{download} = \@download;
	$json{mirror} = \@mirror if @mirror;

	my $changelog = get_release_changelog($repo, $tag);

	my @features;
	my @defects;

	# build list of features
	#
	foreach my $section (sort keys %$changelog) {
		my $list;
		if ($section =~ /improvements/i) {
			$list = \@features;
		} elsif ($section =~ /fixes/i) {
			$list = \@defects;
		} else {
			# (otherwise generally parse errors which we'll ignore)
			next;
		}

		foreach my $item (@{$$changelog{$section}}) {
			my $add = {
				description => $item
			};

			my $component = changelog_entry_components_json($item, $components);
			$$add{component} = $component if @$component;

			push @$list, $add;
		}
	}


	$json{name} = $$release{version};
	$json{summary} = "The focus of this release is $focus";
	$json{date} = git_date($repo, $$release{tag});

	$json{features} = \@features if @features;
	$json{defects} = \@defects if @defects;

	$$release{output} = \%json;
}


#** @function get_component_release_data ($repo, $component, $doclinks)
# @brief Build data structure for each component
#
# Pulls together everything needed to create a component JSON file.
#
# @params $repo		Git::Repository reference
# @params $%component	Hash reference of module/component data
# @params $doclinks	Hash reference of module to URL of documentation
#*

sub get_component_release_data
{
	my ($repo, $component, $doclinks) = @_;

	my %json;

	my @available = ();

	# sort into order to keep git diffs happier...
	#
	foreach my $branch (sort keys %{$$component{branches}}) {
		my ($min, $max) = get_component_release_minmax($$component{branches}{$branch});
		my $branchdata = {
			branch => {
				name => $branch,
				url => "/api/info/branch/$branch/",
			},
			start => {
				name => $min,
				url => "/api/info/branch/$branch/release/$min/",
			},
			end => {
				name => "$max",
				url => "/api/info/branch/$branch/release/$max/",
			},
		};
		push @available, $branchdata;
	}
	$json{available} = \@available;

	$json{name} = $$component{name};
	$json{description} = $$component{readme}{summary} || "";
	$json{category} = $$component{readme}{category} || "";

       	# TODO Well, these are all over the place, so there's no nice easy way
	# to find out where the correct documentation is. The best thing is probably
	# a link in the module README.md file, but for now just link to the generic
	# page rather than specific module documentation.
	#
	if (defined $$doclinks{$$component{name}}) {
		$json{documentation_link} = $$doclinks{$$component{name}};
	} else {
		$json{documentation_link} = "http://networkradius.com/doc/current/raddb/mods-available/home.html";
	}

	$$component{output} = \%json;
}


#** @function git_date ($repo, $branch)
# @brief Get the commit date of a git branch
#
# @params $repo		Git::Repository reference
# @params $branch	Git commit ref
#
# @retval $date		Date of commit
#*

sub git_date
{
	my ($repo, $branch) = @_;

# OK for git 2.6 onwards...
#	my $cmd = $repo->command(show => "-s",
#		"--format=%cd",
#		"--date=format:%Y-%m-%dT%H:%M:%SZ",
#		$branch);
#	my $date = $cmd->stdout->getline();
#	chomp $date;

# ...otherwise,
	my $cmd = $repo->command(show => "-s",
		"--format=%cd",
		"--date=iso",
		$branch);
	my $date = $cmd->stdout->getline();
	chomp $date;

	if ($date =~ /^(\d\d\d\d-\d\d-\d\d) (\d\d:\d\d:\d\d) ([+-]\d\d\d\d)$/) {
		$date = "$1T$2Z"; # this is close enough for the time being...
	} else {
		die "bad date format $date from branch $branch\n";
	}

	return $date;
}

#** @function build_web_json ($relbranches, $versions, $components, $outdir)
# @brief Build JSON files for web site API
#
# Takes information in the component repository data and builds JSON files
# that are picked up by the web site Lua scripts.
#
# @params $%relbranches	Branches available
# @params $%versions	All git versions and tags
# @params $%components	Component repository
# @params $outdir	Directory to put output files
#*

sub build_web_json
{
	my ($relbranches, $versions, $components, $outdir) = @_;
	my $json = JSON->new->pretty(1);

	# sort into order to keep git diffs happier...
	#
	$json->canonical(1);

	# shortcut to write json out to a file
	#
	sub jout
	{
		my ($fn, $js) = @_;
		open my $fh, ">", $fn;
		print $fh $json->encode($js);
		close $fh;
	}

	make_path "$outdir/branch";

	# create branch json for each release version
	#
	foreach my $rv (@$relbranches) {
		my $tag = $$rv{branch};

		my $oj = {
			# this data appears on the "releases" page
			name => $$rv{branch},
			description => $$rv{description},
			status => $$rv{status},
			priority => $$rv{priority} || 9999,
		};
		jout "$outdir/branch/$tag.json", $oj;

		make_path "$outdir/branch/$tag/release";

		# go through each release in the branch and output its json file
		#
		foreach my $release (@{$$rv{releases}}) {
			my $fname = $$release{version};

			# if the branch is development then output the dev (.x)
			# versions, otherwise just output the stable releases
			#
			next if $$rv{status} ne "development" and $fname =~ /x/;

			jout "$outdir/branch/$tag/release/$fname.json", $$release{output};
		}
	}

	make_path "$outdir/component";

	foreach my $component (keys %$components) {
		# TODO this if is a hack to remove old modules that have no available release
		if (scalar (@{$$components{$component}{output}{available}})) {
			jout "$outdir/component/$component.json", $$components{$component}{output};
		}
	}
}



# tests
#
#print "yes 1\n" if version_compare("2.0.0", "2.x.x") == -1;
#print "yes 2\n" if version_compare("2.0.0", "3.0.0") == -1;
#print "yes 3\n" if version_compare("0.1.0", "1.x.x") == -1;
#print "yes 4\n" if version_compare("0.1.0", "3.2.x") == -1;
#print "yes 5\n" if version_compare("3.0.x", "0.9.9") == 1;
#print "yes 6\n" if version_compare("0.9.9", "3.0.x") == -1;
#
#print "yes\n" if version_is_in_branch("2.0.0", "2.x.x");
#print "yes\n" if version_is_in_branch("2.1.0", "2.x.x");
#print "yes\n" if not version_is_in_branch("1.0.0", "2.x.x");
#print "yes\n" if not version_is_in_branch("3.1.5", "2.x.x");
#print "yes\n" if version_is_in_branch("3.0.15", "3.0.x");
#print "yes\n" if version_is_in_branch("3.0.15", "3.x.x");
#print "yes\n" if not version_is_in_branch("3.0.15", "3.1.x");

