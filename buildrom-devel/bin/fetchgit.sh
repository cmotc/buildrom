#!/bin/sh
# Check out or update a GIT repository

URL=$1
DIR=$2
TAG=$3
TARBALL=$4
NAME=$5

# If the base git directory doesn't exist, then we need to clone it

if [ ! -d $DIR/.git ]; then 
	echo "Cloning $URL..."
	git-clone $URL $DIR
	if [ $? -ne 0 ]; then
		echo "Couldn't clone $URL."
		exit 1
	fi
fi

# Fetch the latest and greatest bits

export GIT_DIR=$DIR/.git

git-fetch $URL
git-fetch --tags $URL
git-prune-packed
git-pack-redundant --all | xargs -r rm

# Make the tarball 
git-tar-tree $TAG $NAME-$TAG | bzip2 > $TARBALL
