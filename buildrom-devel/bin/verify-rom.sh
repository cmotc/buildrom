#!/bin/sh

ROM=$1
if [ -z "$ROM" ]; then
	echo "usage: ./verify-rom.sh <rom>"
	exit 1
fi

echo -n "EC:  "
dd if=$ROM bs=1 count=64k 2> /dev/null | md5sum | awk '{print $1}'

echo -n "VSA: "
dd if=$ROM bs=1 skip=64k count=64k 2> /dev/null | md5sum | awk '{print $1}'
