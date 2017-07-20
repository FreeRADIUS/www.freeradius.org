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
# @date 2017-07-11
#*

use strict;
use Data::Dumper;
use File::Path qw(make_path);
use JSON;

use Git::Repository;

my $gitdir = "/srv/freeradius-server";
my $outdir = "/tmp/wsbuild"; # TODO make this a temp dir and then move into place

my $repo = Git::Repository->new( work_tree => $gitdir );


my $RELBRANCHES = [
	{
		# release means find the latest release tag for this branch
		type => "release",
		version => "3.0.x",
		description => "Latest stable branch",
		status => "stable",
	},
	{
		type => "release",
		version => "2.x.x",
		description => "Old stable branch",
		status => "end of life",
	},
	{
		type => "release",
		version => "1.x.x",
		description => "Obsolete stable branch",
		status => "obsolete",
	},
	{
		type => "release",
		version => "0.x.x",
		description => "Obsolete stable branch",
		status => "obsolete",
	},
	{
		# development means just download this actual branch HEAD
		type => "development",
		version => "4.0.x",
		description => "Development branch",
		status => "development",
	},
];


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


#** @function get_module_readme ($repo, $blob)
# @brief Retrieve module README.md and parse it
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

sub get_module_readme
{
	my ($repo, $blob) = @_;
	my $readme = {};

	# read the blob from git
	#
	my $data = $repo->command("show" => $blob)->stdout;
	return undef unless $data;

	#my @lines;
	my $state = "header";
	my $sectionname;
	my $sectiondata;

	while (my $line = $data->getline()) {
		chomp $line;
		#push @lines, $line;

		# at the start, look for a header with a module name
		#
		if ($state eq "header") {
			next if ($line =~ /^\s*$/);

			unless ($line =~ /^#\s+([a-z0-9_]+)$/) {
				die "malformed README header '$line'\n";
			}
			$$readme{modulename} = $1;
			$state = "section";
			next;
		}

		if ($state eq "section") {
			if ($line =~ /^##\s+([A-Za-z]+)$/) {
				if ($sectionname) {
					$$readme{lc $sectionname} = {
						name => $sectionname,
						data => $sectiondata,
					};
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
		$$readme{lc $sectionname} = {
			name => $sectionname,
			data => $sectiondata,
		};
	}

	#$$readme{lines} = \@lines;

	return $readme;
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

#** @function get_release_modules ($repo, $reltag)
# @brief Get all modules included in a particular release
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

sub get_release_modules
{
	my ($repo, $versioninfo) = @_;

	my $reltag = $$versioninfo{tag};

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

	# new data structure to hold all the module details in
	my $modules = {};

	# go through each git object and work out which modules exist
	foreach my $o (@objects) {
		next unless $$o{path} =~ m+^src/modules/+;

		my @components = split /\//, $$o{path};

		# get the relevant module name
		#
		my $name;
		if ($$o{type} eq "tree") {
			# the main module name will always be at the end of the path
			# and begin with rlm_ or proto_
			$name = $components[$#components];
		} else {
			# we only care about README files, so short circuit if not
			next unless $components[$#components] eq "README.md";
			$name = $components[$#components-1];
		}

		# only interested in certain directories
		#
		next unless $name =~ /^(rlm|proto)_/;

		my $module = $modules->{$name} || {};
		$module->{name} = $name;

		# find the parent for submodules
		#
		if ($$o{type} eq "tree" and $#components > 2) {
			$module->{parent} = @components[2];
		}

		# get the module readme
		#
		if ($$o{type} eq "blob") {
			$module->{readmeblob} = $$o{hash};
			#get_module_readme($repo, $$o{hash});
		}

		$modules->{$name} = $module;
	}

	return $modules;
}


#** @function build_modules_repository ($modrepo, $modules, $versioninfo)
# @brief Add data about modules in a release to module repository
#
# Takes information about modules in a particular release and builds up
# a "module repository" which contains data about all modules and which
# releases they are included in.
#
# @params $%modrepo	Hash reference of module repository to add to
# @params $%modules	Data as returned from get_release_modules
# @params $%versioninfo	Hashref with version information for these modules
#
# @retval $%modrepo	Hash reference of module repository
#*

sub build_module_repository
{
	my ($modrepo, $modules, $versioninfo) = @_;

	my $release = $$versioninfo{version};

	# go through all new modules and add to the main module repository
	# as required, tracking release numbers
	#
	foreach my $module (keys %$modules) {
		unless (defined $$modrepo{$module}) {
			$$modrepo{$module} = {
				name => $module,
				minrelease => $release,
				maxrelease => $release,
				maxdevrelease => $release,
				list => [],
			};
		}

		my $mrm = $$modrepo{$module};

		push @{$$mrm{list}}, $$modules{$module};

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
		if ($$versioninfo{type} eq "release") {
			if ($$mrm{minrelease} =~ /x/ or version_compare($$mrm{minrelease}, $release) > 0) {
				$$mrm{minrelease} = $release;
			}

			if ($$mrm{maxrelease} =~ /x/ or version_compare($$mrm{maxrelease}, $release) < 0) {
				$$mrm{maxrelease} = $release;
			}
		}
		else {
			if ($$mrm{minrelease} =~ /x/ and version_compare($$mrm{minrelease}, $release) > 0) {
				$$mrm{minrelease} = $release;
			}

			if ($$mrm{maxrelease} =~ /x/ and version_compare($$mrm{maxrelease}, $release) < 0) {
				$$mrm{maxrelease} = $release;
			}
		}

		# track latest development version, just because
		#
		$$mrm{maxdevrelease} = $release if version_compare($$mrm{maxdevrelease}, $release) < 0;


		# sanity check that parents for different versions are the same
		#
		if (defined $$mrm{parent} and
			($$mrm{parent} ne $$modules{$module}{parent})) {
			die "differing parents for $module";
		}

		# set the parent
		#
		if (defined $$modules{$module}{parent}) {
			$$mrm{parent} = $$modules{$module}{parent};
		}

		# set the readme version
		#
		# don't check for stable/development versions here - see comments above
		#
		if (defined $$modules{$module}{readmeblob}) {
			my $oldversion = $$mrm{readmeversion} || "0.0.0";
			if (version_compare($oldversion, $release) < 0) {
				$$mrm{readmeblob} = $$modules{$module}{readmeblob};
				$$mrm{readmeversion} = $release;
			}
		}
	}

	return $modrepo;
}


#** @function get_readme_files ($modrepo)
# @brief Retrieve all module README.md files
#
# Goes through the module repository and fetches all the README.md files for
# each module from the git repo. Done here rather than earlier so we only pull
# the latest README for each module. If nothing else, earlier READMEs are
# unlikely to be formatted correctly, and therefore will cause the parse sub to
# blow up.
#
# @params $repo		Git::Repository reference
# @params $%modrepo	Hash reference of module repository
#
# @retval $%modrepo	Hash reference of module repository
#*

sub get_readme_files
{
	my ($repo, $modrepo) = @_;

	foreach my $module (sort keys %$modrepo) {
		my $md = $$modrepo{$module};
		next unless defined $$md{readmeblob};

		$$md{readme} = get_module_readme($repo, $$md{readmeblob});
	}
}



#** @function build_web_json ($modrepo, $outdir)
# @brief Build JSON files for web site API
#
# Takes information in the module repository data and builds JSON files that
# are picked up by the web site Lua scripts.
#
# @params $%relbranches	Versions to display on web site
# @params $%versions	All git versions and tags
# @params $%modrepo	Hash reference of module repository
# @params $outdir	Directory to put output files
#*

sub build_web_json
{
	my ($relbranches, $versions, $modrepo, $outdir) = @_;
	my $json = JSON->new->pretty(1);

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
	make_path "$outdir/component";

	# create branch json for each release version
	#
	foreach my $rv (@$relbranches) {
		my $branch = $$rv{branch};

		my $oj = {
			name => $branch.
			description => $$rv{description},
			status => $$rv{status},
		};
		jout "$outdir/branch/$branch.json", $oj;

		make_path "$outdir/branch/$branch/release";

		print "\nbranch: $branch\n";
#		print Dumper $rv;
		foreach my $release (@{$$rv{releases}}) {
			print $$release{version} . "\n";
		}
#		my $reldata = $$rv{releaseinfo};
#		jout "$outdir/branch/$branch/release/
	}

	exit;
}


# dump things in human-readable form (for now)
#
sub output_module_repository
{
	my $modrepo = shift;

	foreach my $module (sort keys %$modrepo) {
		my $md = $$modrepo{$module};

		print "$module:\n";
		print "\tmin: " . $$md{minrelease} . "\n";
		print "\tmax: " . $$md{maxrelease} . "\n";
		print "\tparent: " . $$md{parent} . "\n" if defined $$md{parent};
		print "\treadme blob: " . $$md{readmeblob} . "\n" if defined $$md{readmeblob};
		print "\treadme version " . $$md{readmeversion} . "\n" if defined $$md{readmeversion};
		if (defined $$md{readme}) {
			print "-" x 80 . "\n";
			print Dumper $$md{readme};
			print "-" x 80 . "\n";
		}
		print "\n";
	}
}


# get all versions we're interested in
my $versions = get_versions($repo);

#print "yes 1\n" if version_compare("2.0.0", "2.x.x") == -1;
#print "yes 2\n" if version_compare("2.0.0", "3.0.0") == -1;
#print "yes 3\n" if version_compare("0.1.0", "1.x.x") == -1;
#print "yes 4\n" if version_compare("0.1.0", "3.2.x") == -1;
#print "yes 5\n" if version_compare("3.0.x", "0.9.9") == 1;
#print "yes 6\n" if version_compare("0.9.9", "3.0.x") == -1;

#print "yes\n" if version_is_in_branch("2.0.0", "2.x.x");
#print "yes\n" if version_is_in_branch("2.1.0", "2.x.x");
#print "yes\n" if not version_is_in_branch("1.0.0", "2.x.x");
#print "yes\n" if not version_is_in_branch("3.1.5", "2.x.x");
#print "yes\n" if version_is_in_branch("3.0.15", "3.0.x");
#print "yes\n" if version_is_in_branch("3.0.15", "3.x.x");
#print "yes\n" if not version_is_in_branch("3.0.15", "3.1.x");

#print Dumper $versions;
#print Dumper $RELBRANCHES;
#exit;

#foreach my $k (sort {version_compare($a, $b)} keys %$releases) {
#	next unless $$releases{$k}{type} eq "development";
#	print "$k\n";
#}

# module repository
my $modrepo = {};

#my $ss = get_release_modules($repo, "v4.0.x");
#print Dumper $ss;

# go through all versions and add the modules to the module repository
foreach my $version (keys %$versions) {
	my $release_modules = get_release_modules($repo, $$versions{$version});
	build_module_repository($modrepo, $release_modules, $$versions{$version});
}

# read and parse readme file data
get_readme_files($repo, $modrepo);

# dump everything we've got
output_module_repository($modrepo);

build_web_json($RELBRANCHES, $versions, $modrepo, $outdir);

