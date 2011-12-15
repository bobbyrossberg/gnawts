#!/usr/bin/perl
use IO::Zlib;

&setup_lookups();

if ($#ARGV == 0) {
	$out = $lst = $dump = $ARGV[0];
	$lst =~ s/(dump)/lst/;
	$out =~ s/(dump)/routes/;
}
else {
	$dump = "/var/log/opensm-lfts.dump";
	$lst  = "/var/log/opensm-subnet.lst";
}

&read_routes($dump);
&read_topology($lst);
&print_routes_for_all_host_permutations($out);

exit;

#########################################################################
sub setup_lookups() {
  # node to guid
  $mapfile = &findfile("/admin/etc/GUID.yml");
  open MAP, $mapfile or die "can't open $mapfile: !$\n";
  while (<MAP>) {
	next if /^#/; # eat comments
	($name, $guid) = /^(\S+):\s+0x(\S+)/;
	$name{$guid} = $name;
  }
  close MAP;

  # switch to guid 
  $mapfile = &findfile("/admin/etc/ib-node-name-map.master");
  open MAP, $mapfile or die "can't open $mapfile: !$\n";
  while (<MAP>) {
	next if /^#/; # eat comments
	($guid, $name) = /^0x(\S+)\s+"(\S+)"/;
	$name{$guid} = $name;
  }
  close MAP;
}

sub read_routes() { # port is in decimal
  $f = shift @_;
  $fd = new IO::Zlib;
  $fd->open($f, "r") or die "can't open $f: !$\n";
  while (<$fd>) {
	next if /^#/; # eat comments
	if (/^Unicast lids/) { # a new switch
		($switch) = /'(\S+)'/;
	}
	else {
		if (%name) { # use guid lookups - even for switches
			($guid) = /portguid 0x(\S+):/;
			$dest = $name{$guid};
		}
		else { # depend on pool name being first word of ib description
			($dest) = / '(\S+)/;  #' fix vim syntax coloring
		}
		($port) = / ([0-9]+) /;
		$route{$switch}{$dest} = sprintf "%d", $port;
	}
  }
  $fd->close;
}

sub read_topology() { # port is in hex
  $f = shift @_;
  $fl = new IO::Zlib;
  $fl->open($f, "r") or die "can't open $f: !$\n";
  while (<$fl>) {
	next unless /^\{ SW/; # skip host-first entries (redundant)
	# link has two ends: a and b.  a is always a switch due to the above
	if (%name) { # use guid lookups
		($aguid, $aport, $bguid, $bport) = /PortGUID:(\S+) .* PN:(\S+) .* PortGUID:(\S+) .* PN:(\S+)/;
		$aname = $name{$aguid};
		$bname = $name{$bguid};
	}
	else { # depend on pool name being first word of ib description
		($aname, $aport, $bname, $bport) = /\{(\S+)\} LID:\S+ PN:(\S+) .* \{(\S+).*\} LID:\S+ PN:(\S+)/;
	}
	if (/\{ CA/) {
		# when we add hostlist as CLI arg, expand into %hostlist and uncomment the below
		# next if (%hostlist and exists %hostlist{$bname}); # don't care or already have it
		if ($bname=~/\w/) {
			push @hosts, $bname;
			$b = $bname;
		}
		else {
			print STDERR "No known name for guid $bguid:\n$_";
		}
	}
	else {
		$b = sprintf "%d:%s", hex($bport), $bname;
	}
	$a = sprintf "%d:%s", hex($aport), $aname;
	$link{$a} = $b; 
	$link{$b} = $a; # do both ends of the cable (relates to above "redundant" comments)
  }
  $fl->close;
  @hosts = sort @hosts; # enables efficient detection of route changes
}

sub print_routes_for_all_host_permutations() {
  $f = shift @_;
  $fr = new IO::Zlib;
  $fr->open($f, "w") or die "can't open $f: !$\n";
  foreach $from (@hosts) {
	foreach $to (@hosts) {
		next if ($from eq $to);
		# walk the route
		@hops = ($from, $link{$from});
		while ($hops[-1]=~/\S+:(\S+)$/) {
			$hop = $1;
			$outport = $route{$hop}{$to};
			$hops[-1] .= sprintf ":%d", $outport;
			$a = $outport . ":" . $hop;
			push @hops, $link{$a};
		}
		print $fr join " ", @hops;
		print $fr "\n";
	}
  }
  $fr->close;
}

sub findfile() {
	$file = shift;			# given a /full/path/to/filename
	@F = split /\//, $file;
	$f = $F[-1];
	$file = $f if (-s $f);	# return filename if there is a nonzero one in the cwd
	return $file;		# otherwise return /full/path/to/filename
}
