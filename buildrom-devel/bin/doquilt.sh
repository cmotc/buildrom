#!/bin/bash
# This script sets up the quilt directory and patches the package

DIR=$1; shift

# if the .pc directory already exists, then we will boldy assume
# that quilt has been previously applied.  Aggressively restore the tree
# to pristine

if [ -d $DIR/.pc ]; then
	pushd $DIR > /dev/null
	quilt pop -qaf > /dev/null 2>&1
	popd > /dev/null
fi

mkdir -p $DIR/patches
echo "# $DIR quilt series" > $DIR/patches/series

# If there are no patches to apply, fail cleanly

if [ $# -eq 0 ]; then
	exit 0
fi

while [ $# -gt 0 ]; do
    echo `basename $1` >> $DIR/patches/series
    cp $1 $DIR/patches
    shift
done

cd $DIR
quilt push -qa
