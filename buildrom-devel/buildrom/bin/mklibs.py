#! /usr/bin/python

# mklibs.py: An automated way to create a minimal /lib/ directory.
#
# Copyright 2001 by Falk Hueffner <falk@debian.org>
#                 & Goswin Brederlow <goswin.brederlow@student.uni-tuebingen.de>
#
# mklibs.sh by Marcus Brinkmann <Marcus.Brinkmann@ruhr-uni-bochum.de>
# used as template
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# HOW IT WORKS
#
# - Gather all unresolved symbols and libraries needed by the programs
#   and reduced libraries
# - Gather all symbols provided by the already reduced libraries
#   (none on the first pass)
# - If all symbols are provided we are done
# - go through all libraries and remember what symbols they provide
# - go through all unresolved/needed symbols and mark them as used
# - for each library:
#   - find pic file (if not present copy and strip the so)
#   - compile in only used symbols
#   - strip
# - back to the top

# TODO
# * complete argument parsing as given as comment in main

import commands
import string
import re
import sys
import os
import glob
import getopt
from stat import *

########################## Generic Macros ###########################

DEBUG_QUIET   = 0
DEBUG_NORMAL  = 1
DEBUG_VERBOSE = 2
DEBUG_SPAM    = 3

debuglevel = DEBUG_NORMAL

def debug(level, *msg):
    if debuglevel >= level:
        print string.join(msg)

# A simple set class. It should be replaced with the standard sets.Set
# type as soon as Python 2.3 is out.
class Set:
    def __init__(self):
        self.__dict = {}

    def add(self, obj):
        self.__dict[obj] = 1

    def contains(self, obj):
        return self.__dict.has_key(obj)

    def merge(self, s):
        for e in s.elems():
            self.add(e)

    def elems(self):
        return self.__dict.keys()

    def size(self):
        return len(self.__dict)

    def __eq__(self, other):
        return self.__dict == other.__dict

    def __str__(self):
        return `self.__dict.keys()`

    def __repr__(self):
        return `self.__dict.keys()`

# return a list of lines of output of the command
def command(command, *args):
    debug(DEBUG_SPAM, "calling", command, string.join(args))
    (status, output) = commands.getstatusoutput(command + ' ' + string.join(args))
    if os.WEXITSTATUS(status) != 0:
        if(debuglevel < DEBUG_SPAM):
            print "Failed command: ", command, string.join(args)
        print "Returned " +  str(os.WEXITSTATUS(status)) + " (" + output + ")"
        if debuglevel >= DEBUG_VERBOSE:
            raise Exception
        sys.exit(1)
    return string.split(output, '\n')

# Filter a list according to a regexp containing a () group. Return
# a Set.
def regexpfilter(list, regexp, groupnr = 1):
    pattern = re.compile(regexp)
    result = Set()
    for x in list:
        match = pattern.match(x)
        if match:
            result.add(match.group(groupnr))

    return result

##################### Library Handling ##############################
#
# This section handles libraries, lib_path searching, the soname and
# symlink mess, and should really be made into an object
#

libraries = {} # map from inode to filename (full name, relative to root)
    
# update the libraries global with new inodes 
# Only uses the canonical name, and creates a link from the given
# name to the canonical name
def add_dependencies(obj):
    if not os.access(obj, os.R_OK):
        raise "Cannot find object file: " + obj
    output = command(target + "objdump", "--private-headers", obj)
    depends = regexpfilter(output, ".*NEEDED\s*(\S+)$")
    debug(DEBUG_VERBOSE, obj + " uses libraries " + string.join(depends.elems(),", "))
    
    for library in depends.elems():
	full_path = find_lib(library, root)
	if not full_path or not os.access(root + full_path, os.R_OK):
	    # perhaps the library only exists in the destination
	    full_path = find_lib(library, dest)
	    if full_path:
		present_symbols.merge(provided_symbols(dest + full_path))
	    else:
		raise "Cannot find library: " + library + " for object " + obj
	else:
	    add_library(full_path)

def add_library(library):
        # add the library to the list, unless it's a duplicate
        inode = os.stat(root + library).st_ino
        if libraries.has_key(inode):
            debug(DEBUG_SPAM, library, "is link to", libraries[inode])
        else:
            libraries[inode] = canonical_name(library)
	
	# create a link from this name to the canonical one
	if libraries[inode] == library:
	    pass # this is the canonical name
	elif os.path.dirname(library) == os.path.dirname(libraries[inode]):
	    symlink(dest + library, os.path.basename(libraries[inode]))
	else:
	    symlink(dest + library, libraries[inode]) # must use an absolute name

# Find complete path of a library, by searching in lib_path
# This is done relative to aroot
def find_lib(lib, aroot):
    if lib[0] == '/':
	if os.access(aroot + lib, os.F_OK):
	    return lib
	debug(DEBUG_QUIET, "WARNING: %s does not exist" % lib)
    else:
	for path in lib_path:
	    if os.access(aroot + path + lib, os.F_OK):
		return path + lib
	debug(DEBUG_QUIET, "WARNING: %s not found in search path" % lib, \
	      string.join(lib_path, ":"))
	
    return ""

# returns the canonical name of this library
# First it searches for a valid SONAME: the file must exist
# Then it tries following symlinks
def canonical_name(so_file):
    soname_data = regexpfilter(command(target + "readelf", "--all", "-W", root + so_file),
                               ".*SONAME.*\[(.*)\].*")
    canon = ""

    if soname_data.elems():
	soname = soname_data.elems()[0]
	canon = find_lib(soname, root)

    if not canon:
	canon = resolve_link(so_file)
	
    if canon:
	debug(DEBUG_SPAM, "Canonical name of", so_file, "is", soname)
	return canon
    
    return so_file
     
# Return real target of a symlink (all relative to root)
def resolve_link(file):
    debug(DEBUG_SPAM, "resolving", file)
    while S_ISLNK(os.lstat(root + file)[ST_MODE]):
        new_file = os.readlink(root + file)
        if new_file[0] != "/":
            file = os.path.join(os.path.dirname(file), new_file)
        else:
            file = new_file
    debug(DEBUG_SPAM, "resolved to", file)
    return file

# Return a Set of symbols provided by an object
def provided_symbols(obj):
    if not os.access(obj, os.R_OK):
        raise "Cannot find lib" + obj

    result = Set()
    debug(DEBUG_SPAM, "Checking provided_symbols for", obj)
    output = command(target + "readelf", "-s", "-W", obj)
    for line in output:
        match = symline_regexp.match(line)
        if match:
            bind, ndx, name = match.groups()
            if bind != "LOCAL" and not ndx in ("UND", "ABS"):
                debug(DEBUG_SPAM, obj, "provides", name)
                result.add(name)
    return result

# Find a PIC archive for the library
# this is either an archive of the form base_name_pic.a or
# base_name.a with a _GLOBAL_OFFSET_TABLE_
def find_pic(lib):
    base_name = so_pattern.match(lib).group(1)
    for path in lib_path:
	full = root + path + base_name + "_pic.a"
	debug(DEBUG_SPAM, "checking", full)
        for file in glob.glob(full):
            if os.access(file, os.F_OK):
                return file
    for path in lib_path:
	for file in glob.glob(root + path + base_name + ".a"):
	    relocs = command(target + "objdump", "-r", file)
            # this must be size() > 1 to avoid stripping libdl
	    if os.access(file, os.F_OK) and regexpfilter(relocs,"(.*_GLOBAL_OFFSET_TABLE_)").size() > 1:
               return file
    return ""

# Find a PIC .map file for the library
def find_pic_map(lib):
    base_name = so_pattern.match(lib).group(1)
    for path in lib_path:
        for file in glob.glob(root + path + "/" + base_name + "_pic.map"):
            if os.access(file, os.F_OK):
                return file
    return ""


# Return a list of libraries the passed objects depend on. The
# libraries are in "-lfoo" format suitable for passing to gcc.
def library_depends_gcc_libnames(obj):
    if not os.access(obj, os.R_OK):
        raise "Cannot find lib: " + obj
    output = command(target + "objdump", "--private-headers", obj)
    output = regexpfilter(output, ".*NEEDED\s*lib(\S+)\.so.*$")
    if not output.elems():
        return ""
    else:
        return "-l" + string.join(output.elems(), " -l")

# Scan readelf output. Example:
# Num:    Value          Size Type    Bind   Vis      Ndx Name
#   1: 000000012002ab48   168 FUNC    GLOBAL DEFAULT  UND strchr@GLIBC_2.0 (2)
symline_regexp = \
    re.compile("\s*\d+: .+\s+\d+\s+\w+\s+(\w+)+\s+\w+\s+(\w+)\s+([^\s@]+)")

############################### Misc Functions ######################
    
def add_object(obj):
    inode = os.stat(obj)[ST_INO]
    if objects.has_key(inode):
        debug(DEBUG_SPAM, obj, "is a hardlink to", objects[inode])
    elif script_pattern.match(open(obj).read(256)):
        debug(DEBUG_SPAM, obj, "is a script")
    else:
        objects[inode] = obj
	add_dependencies(obj)
     
	# Check for rpaths
	rpath_val = rpath(obj)
	if rpath_val:
	    if root:
		if debuglevel >= DEBUG_VERBOSE:
		    print "Adding rpath " + string.join(rpath_val, ":") + " for " + obj
	    else:
		print "warning: " + obj + " may need rpath, but --root not specified"
	    lib_path.extend(rpath_val)

# Return a Set of rpath strings for the passed object
def rpath(obj):
    if not os.access(obj, os.R_OK):
        raise "Cannot find lib: " + obj
    output = command(target + "objdump", "--private-headers", obj)
    return map(lambda x: x + "/", regexpfilter(output, ".*RPATH\s*(\S+)$").elems())

# Return undefined symbols in an object as a Set of tuples (name, weakness)
# Besides all undefined symbols, all weak symbols must be included
# because 
def undefined_symbols(obj):
    if not os.access(obj, os.R_OK):
        raise "Cannot find lib" + obj

    result = Set()
    output = command(target + "readelf", "-s", "-W", obj)
    for line in output:
        match = symline_regexp.match(line)
        if match:
            bind, ndx, name = match.groups()
            if bind != "LOCAL" and ndx == "UND":
                comment = ""
                if bind == "WEAK":
                    comment = "(weak)"
                debug(DEBUG_SPAM, obj, "requires", name, comment)
                result.add((name, bind == "WEAK"))
    return result


def usage(was_err):
    if was_err:
        outfd = sys.stderr
    else:
        outfd = sys.stdout
    print >> outfd, "Usage: mklibs [OPTION]... -d DEST FILE ..."
    print >> outfd, "Make a set of minimal libraries for FILE(s) in DEST."
    print >> outfd, "" 
    print >> outfd, "  -d, --dest-dir DIRECTORY     create libraries in DIRECTORY"
    print >> outfd, "  -D, --no-default-lib         omit default libpath (", string.join(default_lib_path, " : "), ")"
    print >> outfd, "  -L DIRECTORY[:DIRECTORY]...  add DIRECTORY(s) to the library search path"
    print >> outfd, "      --ldlib LDLIB            use LDLIB for the dynamic linker"
    print >> outfd, "      --libc-extras-dir DIRECTORY  look for libc extra files in DIRECTORY"
    print >> outfd, "      --target TARGET          prepend TARGET- to the gcc and binutils calls"
    print >> outfd, "      --root ROOT              search in ROOT for library paths"
    print >> outfd, "  -v, --verbose                explain more (usable multiple times)"
    print >> outfd, "  -h, --help                   display this help and exit"
    sys.exit(was_err)
	
def version(vers):
    print "mklibs: version ",vers
    print ""

#################################### main ###########################
## Usage: ./mklibs.py [OPTION]... -d DEST FILE ...
## Make a set of minimal libraries for FILE ... in directory DEST.
## 
## Options:
##   -L DIRECTORY               Add DIRECTORY to library search path.
##   -D, --no-default-lib       Do not use default lib directories of /lib:/usr/lib
##   -n, --dry-run              Don't actually run any commands; just print them.
##   -v, --verbose              Print additional progress information. (can use twice)
##   -V, --version              Print the version number and exit.
##   -h, --help                 Print this help and exit.
##   --ldlib                    Name of dynamic linker (overwrites environment variable ldlib)
##   --libc-extras-dir          Directory for libc extra files
##   --target                   Use as prefix for gcc or binutils calls
## 
##   -d, --dest-dir DIRECTORY   Create libraries in DIRECTORY.
## 
## Required arguments for long options are also mandatory for the short options.

# Clean the environment
vers="0.12"
os.environ['LC_ALL'] = "C"

# Argument parsing
opts = "L:DnvVhd:r:"
longopts = ["no-default-lib", "dry-run", "verbose", "version", "help",
            "dest-dir=", "ldlib=", "target=", "root="]

# some global variables
lib_rpath = []
lib_path = []
dest = "DEST"
ldlib = "LDLIB"
include_default_lib_path = True
default_lib_path = ["/lib", "/usr/lib", "/usr/X11R6/lib"]
target = ""
root = ""
so_pattern = re.compile("(?:.*/)*((lib|ld)[^/]*?)(-[.\d]*)?\.so(\.[^/]]+)*")
script_pattern = re.compile("^#!\s*/")

try:
    optlist, proglist = getopt.getopt(sys.argv[1:], opts, longopts)
except getopt.GetoptError, msg:
    print >> sys.stderr, msg
    usage(1)

for opt, arg in optlist:
    if opt in ("-v", "--verbose"):
        if debuglevel < DEBUG_SPAM:
            debuglevel = debuglevel + 1
    elif opt == "-L":
        lib_path.extend(string.split(arg, ":"))
    elif opt in ("-d", "--dest-dir"):
        dest = arg
    elif opt in ("-D", "--no-default-lib"):
        include_default_lib_path = False
    elif opt == "--ldlib":
        ldlib = arg
    elif opt == "--target":
        target = arg + "-"
    elif opt in ("-r", "--root"):
        root = arg
    elif opt in ("--help", "-h"):
         usage(0)
         sys.exit(0)
    elif opt in ("--version", "-V"):
        version(vers)
        sys.exit(0)
    else:
        print "WARNING: unknown option: " + opt + "\targ: " + arg

if include_default_lib_path:
    lib_path.extend(default_lib_path)

lib_path = map(lambda dir: dir + "/", lib_path)

if ldlib == "LDLIB":
    ldlib = os.getenv("ldlib")

cflags = os.getenv("CFLAGS")

objects = {}  # map from inode to filename (relative to current directory, or absolute)
present_symbols = Set()

for prog in proglist:
    add_object(prog)
    
basenames = map(lambda full: full[string.rfind(full, '/') + 1:], objects.values())
debug(DEBUG_VERBOSE, "Objects:", string.join(basenames))

if not ldlib:
    pattern = re.compile(".*Requesting program interpreter:.*/([^\]/]+).*")
    for obj in objects.values():
        output = command(target + "readelf", "--program-headers", obj)
        for x in output:
             match = pattern.match(x)
             if match:
                 ldlib = match.group(1)
                 break
        if ldlib:
             ldlib = find_lib(ldlib, root)


if not ldlib:
    sys.exit("E: Dynamic linker not found, aborting.")
else:
    debug(DEBUG_NORMAL, "Using", ldlib, "as dynamic linker.")
    add_library(ldlib)

root = root + "/"
dest = dest + "/"
os.umask(0022)

passnr = 1
needed_symbols = Set()              # Set of (name, weakness-flag)

# FIXME: on i386 this is undefined but not marked UND
# I don't know how to detect those symbols but this seems
# to be the only one and including it on alpha as well
# doesn't hurt. I guess all archs can live with this.
needed_symbols.add(("sys_siglist", 1))

while True:
    debug(DEBUG_NORMAL, "library reduction pass", `passnr`)

    passnr = passnr + 1

    # Gather all already reduced libraries and treat them as objects as well
    for lib in libraries.values():
        obj = dest + lib + "-stripped"
        
    # calculate what symbols are present/needed in objects
    previous_count = needed_symbols.size()
    for obj in objects.values():
        needed_symbols.merge(undefined_symbols(obj))
        present_symbols.merge(provided_symbols(obj))
    
    # what needed symbols are not present?
    num_unresolved = 0
    num_weak = 0
    unresolved = Set()
    for (symbol, is_weak) in needed_symbols.elems():
        if not present_symbols.contains(symbol):
            comment = ""
            if(is_weak):
                comment = "(weak)"
                num_weak += 1
            debug(DEBUG_SPAM, "unresolved", symbol, comment)
            unresolved.add((symbol, is_weak))
            num_unresolved += 1

    debug (DEBUG_NORMAL, `needed_symbols.size()`, "symbols,",
           `num_unresolved`, "unresolved", "(" + `num_weak`, " weak)")

    if num_unresolved == 0:
        break

    # if this pass has no more needed symbols, verify all remaining
    # symbols are weak
    if previous_count == needed_symbols.size():
        if num_weak != num_unresolved:
            print "Unresolved symbols:",
            for (symbol, is_weak) in unresolved.elems():
                if not is_weak:
                    print symbol,
            print
            raise Exception
        break

    library_symbols = {}
    library_symbols_used = {}
    symbol_provider = {}

    # Calculate all symbols each library provides
    inodes = {}
    for library in libraries.values():
        path = root + library

	symbols = provided_symbols(path)
        library_symbols[library] = Set()
        library_symbols_used[library] = Set()    
        for symbol in symbols.elems():
            if symbol_provider.has_key(symbol):
                # in doubt, prefer symbols from libc
                if re.match("^libc[\.-]", library):
                    library_symbols[library].add(symbol)
                    symbol_provider[symbol] = library
                else:
                    debug(DEBUG_SPAM, "duplicate symbol", symbol, "in", 
                          symbol_provider[symbol], "and", library)
            else:
                library_symbols[library].add(symbol)
                symbol_provider[symbol] = library

    # which symbols are actually used from each lib
    for (symbol, is_weak) in needed_symbols.elems():
        if symbol_provider.has_key(symbol):
            lib = symbol_provider[symbol]
            library_symbols_used[lib].add(symbol)

    # reduce libraries
    for library in libraries.values():
        stripped = dest + library + "-stripped"
            
        # make the directory to hold the library
        try:
            os.makedirs(os.path.dirname(dest + library));
        except:
            pass

        pic_file = find_pic(library)
        if not pic_file:
            # No pic file, so we have to use the .so file, no reduction
            debug(DEBUG_NORMAL, "copying", library, " (no pic file found)")
            command(target + "objcopy", "--strip-unneeded -R .note -R .comment",
                    root + library, dest + library + "-stripped")
        else:
            # we have a pic file, recompile
            debug(DEBUG_SPAM, "extracting from:", pic_file, "library:", library)
            base_name = so_pattern.match(library).group(1)
            
            if base_name == "libc" and find_lib(ldlib, root):
                # force dso_handle.os to be included, otherwise reduced libc
                # may segfault in ptmalloc_init due to undefined weak reference
                extra_flags = root + find_lib(ldlib, root) + " -u __dso_handle"
            else:
                extra_flags = ""
            map_file = find_pic_map(library)
            if map_file:
                extra_flags = extra_flags + " -Wl,--version-script=" + map_file
            if library_symbols_used[library].elems():
                joined_symbols = "-u" + string.join(library_symbols_used[library].elems(), " -u")
            else:
                joined_symbols = ""
            # compile in only used symbols
            command(target + "gcc",
                cflags + " -nostdlib -nostartfiles -shared -Wl,-soname=" + os.path.basename(library),\
                joined_symbols,
                "-o", dest + "tmp-so",
                pic_file,
                extra_flags,
                "-lgcc",
                "-L" + string.join(map(lambda orig: dest + orig, lib_path), " -L"), \
                "-L" + string.join(map(lambda orig: root + orig, lib_path), " -L"), \
                library_depends_gcc_libnames(root + library))
            # strip result
            command(target + "objcopy", "--strip-unneeded -R .note -R .comment",
                      dest + "tmp-so",
                      dest + library + "-stripped")
            ## DEBUG
            debug(DEBUG_VERBOSE, "reducing", library, "\t", 
                  "original:", `os.stat(root + library)[ST_SIZE]`,
                  "reduced:", `os.stat(dest + "tmp-so")[ST_SIZE]`,
                  "stripped:", `os.stat(stripped)[ST_SIZE]`)
	    debug(DEBUG_SPAM, "using: " + string.join(library_symbols_used[library].elems()))
            
	    os.remove(dest + "tmp-so")

        # add the library to the list of objects (if not there already)
        if stripped not in objects.values():
            debug(DEBUG_VERBOSE, "adding object", stripped)
	    add_object(stripped)
    
# Finalising libs and cleaning up
for lib in libraries.values():
    os.rename(dest + lib + "-stripped", dest + lib)

# Make sure the dynamic linker is present and is executable
if ldlib:
    debug(DEBUG_NORMAL, "stripping and copying dynamic linker.")
    command(target + "objcopy", "--strip-unneeded -R .note -R .comment",
            root + ldlib, dest + ldlib)
    os.chmod(dest + ldlib, 0755)
