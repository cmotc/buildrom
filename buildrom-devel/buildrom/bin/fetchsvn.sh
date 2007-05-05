#!/bin/sh
# Check out or update a SVN repository

URL=$1
DIR=$2
REV=$3
TARBALL=$4

# Simple case - the repository doesn't exist

if [ ! -d $DIR/svn/.svn ]; then
	echo "Fetching $URL..."	
	svn co -r $REV $URL $DIR/svn
	if [ $? -ne 0 ]; then
		echo "Couldn't fetch the code from $URL"
		exit 1
	fi	
else
	CURREV=`svn info $DIR/svn | grep "Last Changed Rev" | awk '{ print $4 }'`

	if [ $CURREV -ne $REV ]; then
		(cd $DIR/svn; \
		echo "Updating from $CURREV to $REV"
		svn update -r $REV || {
			echo "Couldn't update the repository."
			exit 1
		})
	fi
fi

tar -C $DIR -zcf $TARBALL svn 
