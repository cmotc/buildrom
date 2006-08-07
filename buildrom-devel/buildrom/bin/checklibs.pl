#!/usr/bin/perl

# Written by Jordan Crouse (jordan@cosmicpenguin.net)
# With assistance from Erik Andersen (andersee@codepoet.org)
#
# Released under the General Public License

# This script will examine all of the libraries in a target
# directory, and verify that all the nessesary libraries are
# in place.
#
# There are four different modes to this script: 
#
# ./checklibs.pl --copy [TARGET] [SOURCE] ....
# Copy all the nessesary libraries (and symlinks from the 
# source directory(ies) to [TARGET]/lib

# ./checklibs.pl --list [TARGET]
# List all of the required libraries in the target directory

# ./checklibs.pl --verify [TARGET]
# See if any files in [TARGET]/lib are unnessesary

# ./checklibs.pl --files [TARGET]
# Show all of the binary files / shared libraries, and list
# the libraries that they depend on 
#
# Any of the above modes accept --silent to make them quiet
# Specifying --script only makes sense for --verify - it lists the unneeded libraries as a 
# list, suitable for using in scripts

use strict;
use File::Find;
use File::Basename;
use Getopt::Long;

my $ACTION_COPY=0;
my $ACTION_LIST=1;
my $ACTION_VERIFY=2;
my $ACTION_FILES=3;

my $action = -1;
my $silent = 0;
my $script = 0;

my @options = ("copy" => sub { $action = $ACTION_COPY; },
	       "list" => sub { $action = $ACTION_LIST; },
	       "verify" => sub { $action = $ACTION_VERIFY; },
	       "files" => sub { $action = $ACTION_FILES; },
	       "script" => \$script,
	       "silent" => \$silent);

GetOptions(@options);

die "Error - you must specify an action\n" if ($action == -1);

my (@libs) = ();

my ($targetdir) = $ARGV[0]; # Always the first non option item 
my ($file) = "";
my ($pwd) = $ENV{'PWD'};
my (%filea);
my ($ldd) = "/usr/bin/ldd";

if (defined($ENV{'LDD'})) {	
	$ldd = $ENV{'LDD'};
}

die "Couldn't find $ldd!" unless (-f $ldd);

print "Getting files in $targetdir..\n" if (!$silent);

# For every binary in the tree, get the list of libraries

find sub {  

    if ( -f $_ && ! -d $_ ) {
	my $res;
	$file = "$File::Find::name";

	$res = `file $file`;
	if ( $res ) { 
	    if ($res =~ /ELF/ ) {	

		if (! /statically/ ) {
		    $_ = `$ldd $file 2> /dev/null`;
		    while( /[ \t]*(.*) => (.*)/g ) {
			my $lib = basename($1);
			next if (ord($lib) > 128);
			push(@libs, $lib);
			push @{ $filea{$lib} }, $file;
		    }
		}
	    }

	}
    }
}, $targetdir;


# Now, keep going through the list, and add any new dependancies

my($libdir) = "$targetdir/lib";
my (%seen) = ();
my (@uniqlibs) = grep { ! $seen{$_} ++ } @libs;

foreach $_ ( @uniqlibs ) {
    my @local = split(/ /, $_);
    
    $file = "$libdir/$local[0]";
    
    # ldd reaches through symbolic links  
    my($r) = `$ldd $file 2> /dev/null`;

    while($r =~ /[ \t]*(.*) => (.*)/g ) {
	my $f = $1;
        my ($base) = basename($f);

	if ( ! $seen{$base} ) { 
	    push(@uniqlibs, $base);
	    $seen{$base}++;
	}
    }
}
my(@sortlibs) = sort @uniqlibs;

if ($action == $ACTION_COPY) { copy_libraries(); }
elsif ($action == $ACTION_LIST) { list_libraries(); }
elsif ($action == $ACTION_VERIFY) { verify_libraries(); }
elsif ($action == $ACTION_FILES) { show_files(); }

sub show_files {
    foreach (keys %filea) {
	my $first = 0;
	print "$_:  ";
	foreach my $f (@{ $filea{$_} }) {
	    print "," if ($first++);
	    print basename($f);
	}
	print "\n";
    }
}

# For each file in the target directory, see if we need it or not

sub verify_libraries {
    my (@dirlist);

    opendir(DIR, $libdir);
    @dirlist = grep { ! -d "$libdir/$_" } readdir(DIR);
    closedir(DIR);

    foreach my $f (@dirlist) {
	my ($found) = 0;

	foreach my $l (@sortlibs) {
	    my ($libfile) = "$libdir/$l";
	    if ($l eq basename($f)) {
		$found = 1;
		last;
	    }
	    if (-l $libfile) {
		my ($link) = readlink $libfile;
		if (basename($link) eq basename($f)) {
		    $found = 1;
		    last;
		}
	    }
	}

	if (!$found) {
	    if ($script) {
		print "$f\n";
	    } else {
		print "File $f is not needed by the current tree\n";
	    }
	}
    } 
}

sub list_libraries {
   foreach $_ ( @sortlibs) {
       my ($libfile) = "$libdir/$_";
       print "$_: ";

       if (-l $libfile) {
	   my ($link) = basename(readlink $libfile);
	   print " $_ => $link";
       }
       elsif (-f $libfile) {
	   print " $_";
       }
       else { print "*NOT FOUND*"; }
       print "\n";
   }
}

sub copy_libraries {
    my @copylibs;
    my $dir;
    my $lib;

    for(my $i = 1; $i <= $#ARGV; $i++) {
	push @copylibs, $ARGV[$i];
    }

    my (@args) = ("cp", "-a", "", "");

    print "Copying needed libraries:\n" if (!$silent);
    
    COPYLIB: foreach $lib ( @sortlibs) {
      LIBS: foreach $dir (@copylibs) {
	  my $file = "$dir/$lib";
	  
	  next LIBS unless (-e $file || -l $file);

	  my ($libfile) = "$dir/$lib";
	  my $stat = 0;
	  
	  my ($libname) = basename($libfile);

	  $args[2] = "$libfile";
	  $args[3] = "$targetdir/lib";
	  print "Copying $libname...\n" if (!$silent);
	  system(@args);

	  if (-l $libfile) {
	      my $targetlink = readlink $libfile;
		  
	      if (-e "$dir/$targetlink") { 		 
		  $args[2] = "$dir/$targetlink";
		  $args[3] = "$targetdir/lib";
		  print "Copying $dir/$targetlink...\n" if (!$silent);
		  system(@args);
	      }
	  }

	  next COPYLIB;
      }
    }
}  


