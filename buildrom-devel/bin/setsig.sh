#!/bin/sh

# These should be fairly static - we can make them dynamic if we have to

START="FFFC0"
LEN="16"

STR_BEGIN=`dc -e "16 i FFFC0 p"`
STR_END=`expr $STR_BEGIN + $LEN`

IN=$1
SIG=$2
OUT=$3

if [ -z "$IN" -o -z "$SIG" ]; then
	echo "usage:  ./setsig.sh <input> <sig> <output>"
	exit 1
fi

if [ -z "$OUT" ]; then
	OUTPUT=/dev/stdout
fi

dd if=$IN bs=$STR_BEGIN count=1 > $OUT 2>/dev/null
echo -n "$SIG" >> $OUT
dd if=$IN bs=$STR_END skip=1 >> $OUT 2>/dev/null
