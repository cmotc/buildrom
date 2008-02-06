#!/bin/sh
# Check out or update a SVN repository

URL=$1
DIR=$2
REV=$3
TARBALL=$4

SVNV=`svn --version --quiet`

if [ $? -ne 0 ]; then
	echo "You don't have SVN installed."
	exit 1
fi

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
		if [ `echo $?` -ne 0 ]; then
			# The parentheses around the cd $DIR/svn; svn update ... commands above
			# cause those commands to be executed as a list, in a subshell. As a
			# consequence, if something goes wrong the exit command exits the
			# subshell, not the script. And that means that the tar command below was
			# still being executed even if the svn checkout failed, which could lead
			# to nasty, nasty situations where we had a tarball that claimed to be a
			# certain SVN revision, but was really some other revision...
		  exit 1
		fi
	fi
fi

tar -C $DIR -zcf $TARBALL svn 
