#!/bin/sh -e
# Usage: ./construct-rom.sh [-p] components ...

DOPAD=0

if [ "$1" == "-p" ]; then
	DOPAD=1
	shift
fi

COMPONENTS=$*

if [ $DOPAD -eq 1 ]; then

	ROMSIZE=0

	# Get the size of all the components together

	for c in $COMPONENTS; do
		size=`du -b $c | cut -f1`
		ROMSIZE=`expr $ROMSIZE + $size` || true
	done

	# Pad to a power of 2, starting with 128k
	RSIZE=131072

	while true; do
		PAD=0

		if [ $ROMSIZE -gt $RSIZE ]; then
			RSIZE=`expr $RSIZE "*" 2`
			continue
		fi

		if [ $ROMSIZE -lt $RSIZE ]; then
			PAD=`expr $RSIZE - $ROMSIZE`
		fi

		break
	done

	PADFILE=`mktemp`
	dd if=/dev/zero of=$PADFILE bs=1 count=$PAD > /dev/null 2>&1
	COMPONENTS="$PADFILE $COMPONENTS"
fi

cat $COMPONENTS

if [ $DOPAD -eq 1 ]; then
	rm -rf $PADFILE
fi
