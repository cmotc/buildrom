#!/bin/sh

size=`du -b $1 | cut -f1`
delta=`expr 884736 - $size`
echo "Bytes left in ROM: $delta"

if [ $delta -lt 0 ]; then 
	echo "ERROR! ERROR! ERROR!"
	echo "The ELF image $1 is too big!"
	exit -1
fi

exit 0
