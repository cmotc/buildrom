#!/bin/sh

# These should be fairly static - we can make them dynamic if we have to

START="FFFC0"
LEN="16"

STR_BEGIN=`dc -e "16 i FFFC0 p"`
STR_END=`expr $(STR_BEGIN) + $(LEN)`

IN=$1

if [ -z "$IN" -o -z "$SIG" ]; then
	echo "usage:  ./getsig.sh <rom>"
	exit 1
fi

dd if=$IN bs=1 skip=$STR_BEGIN count=$LEN 2>/dev/null
