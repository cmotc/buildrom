#!/bin/sh
# Check out or update a SVN repository

URL=$1
DIR=$2
REV=$3

BASE=`dirname $DIR`

# Simple case - the repository doesn't exist

if [ ! -d $DIR/.svn ]; then
	(cd $BASE; \
	svn co -r $REV $URL || {
		echo "Couldn't get the repository."
		exit 1
	})

	exit 0
fi

CURREV=`svn info $DIR | grep "Last Changed Rev" | awk '{ print $4 }'`

if [ $CURREV -ne $REV ]; then
	(cd $DIR; \
	svn update -r $REV $URL || {
		echo "Couldn't update the repository."
		exit 1
	})

        exit 0
fi

