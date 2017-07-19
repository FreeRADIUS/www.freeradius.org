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

use Git::Repository;

my $gitdir = "/srv/freeradius-server";

my $repo = Git::Repository->new( work_tree => $gitdir );


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
	my %versions = map {/^release_(\d+)_(\d+)_(\d+)$/ ? ("$1.$2.$3", {tag => $_, type => "release"}) : ()} @tags;

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
			};
		}
	}

	return \%versions;
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
# @params $reltag	Git tag name or object
#
# @retval $%modules	Hash reference of module name => module information
#*

sub get_release_modules
{
	my ($repo, $reltag) = @_;

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


#** @function build_modules_repository ($modrepo, $modules, $release)
# @brief Add data about modules in a release to module repository
#
# Takes information about modules in a particular release and builds up
# a "module repository" which contains data about all modules and which
# releases they are included in.
#
# @params $%modrepo	Hash reference of module repository to add to
# @params $%modules	Data as returned from get_release_modules
# @params $release	Version these modules are in (e.g. "3.0.8")
#
# @retval $%modrepo	Hash reference of module repository
#*

sub build_module_repository
{
	my ($modrepo, $modules, $release) = @_;

	# go through all new modules and add to the main module repository
	# as required, tracking release numbers
	#
	foreach my $module (keys %$modules) {
		unless (defined $$modrepo{$module}) {
			$$modrepo{$module} = {
				name => $module,
				minrelease => $release,
				maxrelease => $release,
				list => [],
			};
		}

		my $mrm = $$modrepo{$module};

		push @{$$mrm{list}}, $$modules{$module};

		$$mrm{minrelease} = $release if version_compare($$mrm{minrelease}, $release) > 0;
		$$mrm{maxrelease} = $release if version_compare($$mrm{maxrelease}, $release) < 0;
		if (defined $$mrm{parent} and
			($$mrm{parent} ne $$modules{$module}{parent})) {
			die "differing parents for $module";
		}
		if (defined $$modules{$module}{parent}) {
			$$mrm{parent} = $$modules{$module}{parent};
		}
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


# get all release tags with version numbers
my $releases = get_releases($repo);

# testing, for now
$$releases{"2.99.99"} = "v2.x.x";
$$releases{"3.0.99"} = "v3.0.x";
$$releases{"4.0.0"} = "v4.0.x";

# module repository
my $modrepo = {};

my $ss = get_release_modules($repo, "v4.0.x");
#print Dumper $ss;

# go through all versions and add the modules to the module repository
foreach my $version (keys %$releases) {
	my $release_modules = get_release_modules($repo, $$releases{$version});
	build_module_repository($modrepo, $release_modules, $version);
}

# read and parse readme file data
get_readme_files($repo, $modrepo);

# dump everything we've got
output_module_repository($modrepo);

